# Local conversational engine — intentionally has zero external LLM dependency.
# It produces natural, varied wellness responses by matching user input against a
# small set of intents, using whatever chart context is passed in (latest vitals,
# nutrition, workouts, goals) plus a vetted wellness knowledge base.
#
# This is the always-available "grounded" floor of the Sage provider chain: it
# runs fully in-process, so on the default configuration a member's questions and
# health data never leave the server. It never raises and never returns blank.
#
# IMPORTANT: Sage is a wellness companion, not a clinician. It does not diagnose
# or prescribe, it nudges members toward their care team for anything medical,
# and it escalates urgent/crisis messages to 911 / 988 before anything else.
class SageAiService
  TIPS = [
    "Drink a glass of water first thing — most of us start the day mildly dehydrated.",
    "Get a few minutes of morning daylight; it anchors your sleep rhythm and lifts mood.",
    "Add one extra serving of vegetables today — fiber feeds a healthy gut.",
    "Take a 10-minute walk after a meal to steady your energy and digestion.",
    "Aim for protein at every meal; it keeps you full and protects muscle.",
    "Try a two-minute breathing reset: in for 4, out for 6. Your nervous system will thank you.",
    "Lay out tomorrow's workout clothes tonight — make the healthy choice the easy one.",
    "Wind down screens an hour before bed for deeper, more restorative sleep.",
    "Stand up and stretch every hour you're sitting; movement snacks add up.",
    "Celebrate showing up, not being perfect — consistency is what compounds."
  ].freeze

  # Caught by deterministic rules before any model runs — never gated on latency.
  EMERGENCY_RESPONSE = "This sounds like it could be a medical emergency. If you're having chest pain, " \
                       "trouble breathing, signs of a stroke, or you feel like you might harm yourself, " \
                       "please call 911 right now (or your local emergency number). You can also call or " \
                       "text 988 for the Suicide & Crisis Lifeline — free, confidential, 24/7. " \
                       "I'm a wellness companion, not a doctor, and your safety comes first.".freeze

  GREETING_OPENERS = [
    "Hey there — ",
    "Hi! ",
    "Hello! ",
    "Hey, "
  ].freeze

  def chat(message, context: nil, history: [])
    msg = message.to_s.strip
    return "Tell me what's on your mind — your nutrition, movement, sleep, stress, or your chart." if msg.empty?

    intent = classify(msg)
    respond(intent, msg, context, history)
  rescue StandardError => e
    Rails.logger.error("[Sage] #{e.class}: #{e.message}")
    # We never tell the user we're having trouble — fall back to a tip.
    "I'm here to support your wellness. Quick tip while I gather my thoughts: #{TIPS.sample}"
  end

  private

  # Two-stage intent detection. Crisis/urgent-care messages are always caught
  # first by fast, deterministic rules — we never gate a 911/988 response on model
  # latency or confidence. Otherwise we ask the on-device DistilBERT zero-shot
  # classifier (Sage::IntentClassifier); when it isn't available or isn't
  # confident it returns nil and we fall through to the rule-based classifier.
  def classify(msg)
    m = msg.downcase
    return :emergency if emergency?(m)

    neural = Sage::IntentClassifier.classify(msg)
    return neural if neural

    classify_by_rules(m)
  end

  # Deterministic crisis/urgent-care detection. Kept broad on purpose: a false
  # positive just adds a "call 911/988" line; a false negative could miss a
  # genuine emergency.
  def emergency?(m)
    m.match?(/\b(911|emergency|can'?t breathe|cant breathe|chest pain|heart attack|stroke|overdose|passing out|suicid|kill myself|end my life|harm myself|hurt myself|self[\s-]?harm)\b/)
  end

  # Legacy regex intent matching — the always-available fallback when the neural
  # classifier is disabled/unavailable. Specific topics are matched before generic
  # ones.
  # Stems are matched with a leading word boundary but no trailing one, so common
  # inflections are caught ("bloat" → "bloating", "exhaust" → "exhausted"). More
  # specific topics are checked before generic ones; the neural classifier, when
  # available, runs first and handles anything these rules miss.
  def classify_by_rules(m)
    return :greeting   if m.match?(/\A\s*(hi|hello|hey|yo|sup|good (morning|afternoon|evening))\b/)
    return :thanks     if m.match?(/\b(thank|appreciate it|got it)/)
    return :goodbye    if m.match?(/\b(bye|goodbye|see ya|later)\b/)
    return :worried    if m.match?(/\b(discourag|unmotivat|gave up|giv(e|ing) up|fell off|can'?t do this|hopeless|frustrat|failing|failed|quit)/)
    return :gut        if m.match?(/\b(gut|digest|bloat|microbiome|stomach|ibs|constipat|fiber)/)
    return :hydration  if m.match?(/\b(water|hydrat|thirsty|dehydrat)/)
    return :sleep      if m.match?(/\b(sleep|insomnia|tired|rest|nap|awake|waking|wake up|bedtime|exhaust|drowsy)/)
    return :stress     if m.match?(/\b(stress|anxi|overwhelm|burnout|burn out|mindful|meditat|breath|calm)/)
    return :nutrition  if m.match?(/\b(eat|food|diet|nutrition|meal|calorie|macro|protein|carb|sugar|snack|recipe)/)
    return :fitness    if m.match?(/\b(workout|exercise|train|gym|lift|strength|cardio|run|muscle|fitness|stretch|mobility)/)
    return :weight     if m.match?(/\b(weight|lose weight|fat loss|bmi|slim|deficit|scale)/)
    return :vitals     if m.match?(/\b(blood pressure|heart rate|resting hr|pulse|vitals|systolic|diastolic)\b/)
    return :habit      if m.match?(/\b(habit|streak|consistent|consistency|routine|stick to|on track)/)
    return :tips       if m.match?(/\b(tip|advice|how do i|where do i start|suggestion|recommend)/)
    return :stats      if m.match?(/\b(my (score|progress|stats|chart|numbers|data)|how am i doing|overview|summary)/)
    :default
  end

  def respond(intent, msg, context, history)
    # Specific topical questions are best served by the vetted knowledge base;
    # fall back to the generic category blurb if the retriever has no confident match.
    if %i[gut nutrition sleep stress fitness weight hydration].include?(intent) && (kb = Sage::Knowledge.answer(msg))
      return with_disclaimer(kb)
    end

    case intent
    when :emergency  then EMERGENCY_RESPONSE
    when :greeting   then greeting_response(context)
    when :thanks     then thanks_response
    when :goodbye    then "Take care of yourself. Small steps, every day — I'm here whenever you need me."
    when :worried    then worried_response(context)
    when :nutrition  then nutrition_response(context)
    when :gut        then gut_response
    when :hydration  then hydration_response(context)
    when :sleep      then sleep_response(context)
    when :stress     then stress_response
    when :fitness    then fitness_response(context)
    when :weight     then weight_response(context)
    when :vitals     then vitals_response(context)
    when :habit      then habit_response(context)
    when :tips       then tips_response
    when :stats      then stats_response(context)
    else                  default_response(msg, context, history)
    end
  end

  # Append the not-medical-advice note to substantive health guidance, without
  # repeating it on light/social turns.
  def with_disclaimer(text)
    "#{text}\n\n_#{Sage::Knowledge::DISCLAIMER}_"
  end

  def greeting_response(context)
    opener = GREETING_OPENERS.sample
    name   = context&.dig(:first_name)
    goal   = context&.dig(:primary_goal)
    who    = name.present? ? "#{opener.strip} #{name} — " : opener
    if goal.present?
      "#{who}I'm Sage, your wellness companion. I see you're working toward #{goal.to_s.downcase}. Ask me about nutrition, movement, sleep, stress, or how your chart is trending."
    else
      "#{who}I'm Sage, your holistic wellness companion. Ask me about nutrition, gut health, workouts, sleep, stress, or your own progress — or just say 'tips'."
    end
  end

  def thanks_response
    [
      "Anytime — you're doing the work, I'm just here to help.",
      "You got it. Keep showing up for yourself.",
      "Glad that helped. I'm here whenever you need a nudge."
    ].sample
  end

  def worried_response(context)
    name = context&.dig(:first_name)
    lead = name.present? ? "I hear you, #{name}. " : "I hear you. "
    "#{lead}Falling off is part of the process, not the end of it — what matters is the next step, not the lost days. " \
    "Let's shrink it until it's easy:\n1. #{TIPS.sample}\n2. #{TIPS.sample}\n3. Do just that today, then check in tomorrow. " \
    "Your streak resets, not your worth."
  end

  def nutrition_response(context)
    target = context&.dig(:calorie_target)
    eaten  = context&.dig(:today_calories)
    base = "Build plates around plants, quality protein, whole-food carbs, and healthy fats — half the plate veggies is a simple frame. Protein at each meal keeps you full and protects muscle."
    if target.to_i.positive?
      remaining = target.to_i - eaten.to_i
      base += eaten.to_i.positive? ?
        " You've logged about #{eaten.to_i} of your ~#{target.to_i} kcal target today (#{remaining.positive? ? "#{remaining} left" : "a little over — no big deal, it evens out"})." :
        " Your personalized target is about #{target.to_i} kcal/day — log your meals on the chart and I'll help you balance the day."
    end
    with_disclaimer(base)
  end

  def gut_response
    with_disclaimer(Sage::Knowledge.answer("gut health digestion bloating") || Sage::Knowledge::ENTRIES.first[:text])
  end

  def hydration_response(_context)
    with_disclaimer("Hydration powers energy, digestion, and recovery. A good default is roughly half your bodyweight (lbs) in ounces of water a day — more when it's hot or you train. Keep a bottle visible, front-load the morning, and check for pale-yellow urine. Log water in your daily check-in and watch the trend.")
  end

  def sleep_response(context)
    hrs = context&.dig(:sleep_hours)
    base = "Sleep is where recovery happens. Anchor a steady wake time, get morning daylight, keep the room cool and dark, and dim screens the last hour. Most adults do best with 7–9 hours."
    base += " Your latest check-in logged about #{hrs} hours — #{hrs.to_f < 7 ? "let's nudge that up with an earlier wind-down" : "nice work keeping that in a healthy range"}." if hrs
    with_disclaimer(base)
  end

  def stress_response
    with_disclaimer("Chronic stress shows up as poor sleep, cravings, and tight digestion. Try a two-minute breathing reset (in for 4, out for 6), a short walk outside, or 10 quiet minutes. Name what's in your control and protect one screen-free pocket a day. If anxiety feels constant or overwhelming, a therapist can really help.")
  end

  def fitness_response(context)
    mins = context&.dig(:week_minutes)
    base = "The best routine is the one you'll repeat. Aim for ~150 minutes of movement a week plus two strength sessions covering a squat, hinge, push, pull, and carry. Start light, progress slowly, and treat rest days as part of the plan."
    if mins
      base += mins.to_i >= 150 ?
        " You're at #{mins.to_i} active minutes this week — that's the target, nicely done." :
        " You've logged #{mins.to_i} active minutes this week; even a few 10-minute walks will close the gap to ~150."
    end
    with_disclaimer(base)
  end

  def weight_response(context)
    bmi = context&.dig(:bmi)
    cat = context&.dig(:bmi_category)
    base = "Sustainable change comes from a modest calorie deficit you can live with (often 300–500 below maintenance), plenty of protein, and strength work to keep muscle. Judge progress over weeks — the scale zig-zags with water and hormones."
    base += " Your current BMI is about #{bmi} (#{cat&.downcase}); remember BMI is just one screen — how you feel, your energy, and your waist trend matter more." if bmi
    with_disclaimer(base)
  end

  def vitals_response(context)
    bp  = context&.dig(:blood_pressure)
    cat = context&.dig(:bp_category)
    hr  = context&.dig(:resting_hr)
    parts = []
    parts << "your last blood pressure logged #{bp} (#{cat&.downcase})" if bp
    parts << "resting heart rate around #{hr}" if hr
    lead = parts.any? ? "From your chart, #{parts.join(' and ')}. " : ""
    with_disclaimer("#{lead}Lifestyle moves vitals: regular movement, less sodium and ultra-processed food, more potassium-rich plants, good sleep, and stress care. Log readings at the same time of day. Consistently high blood pressure should be reviewed with your clinician — and never stop a prescribed medication on your own.")
  end

  def habit_response(context)
    streak = context&.dig(:streak).to_i
    lead = streak.positive? ? "You're on a #{streak}-day check-in streak — that's momentum worth protecting. " : ""
    "#{lead}Habits stick when they're tiny and anchored: attach the new one to something you already do ('after coffee, I stretch'), make it laughably small, and track it. Don't break the chain twice in a row, and lean on identity — 'I'm someone who moves daily' beats willpower."
  end

  def tips_response
    picks = TIPS.sample(3)
    "Three small things that move the needle:\n1. #{picks[0]}\n2. #{picks[1]}\n3. #{picks[2]}"
  end

  def stats_response(context)
    return "Open your Chart Summary and I can speak to the specifics. In the meantime, tell me what you'd like to focus on — nutrition, movement, sleep, or stress?" if context.blank?

    bits = []
    bits << "a wellness score of #{context[:wellness_score]}" if context[:wellness_score]
    bits << "#{context[:streak]} day check-in streak" if context[:streak].to_i.positive?
    bits << "#{context[:week_minutes]} active minutes this week" if context[:week_minutes]
    bits << "~#{context[:today_calories]} kcal logged today" if context[:today_calories].to_i.positive?
    if bits.any?
      "Here's your snapshot: #{bits.join(', ')}. Want me to dig into any one of those — or suggest the next small step?"
    else
      "Your chart is just getting started. Log a check-in, a meal, or a workout and I'll start spotting trends and tailoring suggestions."
    end
  end

  def default_response(msg, context, history)
    # A vetted, semantically-retrieved answer wins when the question maps to
    # something in our wellness knowledge base (zero model, zero data leaving).
    kb = Sage::Knowledge.answer(msg)
    return with_disclaimer(kb) if kb

    name = context&.dig(:first_name)
    lead = name.present? ? "#{name}, " : ""
    if history && history.size > 1
      "#{lead}tell me a bit more — is this about nutrition, movement, sleep, stress, gut health, or your chart? I'll tailor it to you."
    else
      "#{lead}I'm your holistic wellness companion. Ask me about nutrition, gut health, workouts, sleep, stress, hydration, or your own progress — or say 'tips' for a few quick wins."
    end
  end
end
