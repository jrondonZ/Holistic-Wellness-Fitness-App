module Sage
  # A curated, vetted holistic-wellness knowledge base + semantic search over it
  # (via Sage::Retriever). This is what lets the always-free grounded engine
  # answer real questions ("how do I reduce bloating?", "what should I eat after
  # a workout?") with accurate, actionable guidance instead of a generic "tell me
  # more" fallback — with zero model download and no API key, so member questions
  # never leave the server.
  #
  # Content is intentionally general, evidence-aligned wellness education in the
  # spirit of the Holistic Wellness Fitness pillars (wellness, diet, fitness,
  # education). It is NOT medical advice: it never diagnoses, never prescribes,
  # and routes anything urgent to a clinician or the crisis lines. Member-specific
  # numbers come from the live chart context, never from here.
  module Knowledge
    DISCLAIMER = "This is general wellness education, not medical advice — for anything " \
                 "concerning or persistent, check with your care team or a licensed clinician.".freeze

    ENTRIES = [
      { topic: "gut health digestion microbiome and reducing bloating",
        text: "A happy gut loves fiber diversity, fermented foods (yogurt, kefir, kimchi, sauerkraut), and steady hydration. Aim for 25–35g of fiber a day, chew slowly, and notice trigger foods. Bloating often eases when you cut ultra-processed foods and added sugar, walk after meals, and keep a consistent eating rhythm. Persistent pain, blood, or sudden changes deserve a clinician's eyes." },
      { topic: "anti-inflammatory eating and whole foods nutrition",
        text: "Build plates around colorful vegetables, fruit, legumes, whole grains, olive oil, nuts, and fatty fish, and lean away from ultra-processed foods, refined sugar, and excess alcohol. A simple frame: half the plate plants, a quarter quality protein, a quarter whole-food carbs. You don't need to be perfect — consistency beats intensity." },
      { topic: "protein intake and building or keeping muscle",
        text: "Protein keeps you full and protects muscle, especially when you're losing weight or training. A common target is about 0.7–1g per pound of goal bodyweight, spread across meals. Easy sources: eggs, Greek yogurt, beans and lentils, tofu/tempeh, fish, poultry, and a scoop of protein after workouts. Pair protein with fiber for steady energy." },
      { topic: "hydration and how much water to drink",
        text: "Hydration powers energy, digestion, and recovery. A reasonable default is roughly half your bodyweight in pounds as ounces of water a day, more when it's hot or you train hard. Front-load water in the morning, keep a bottle visible, and check the simple gauge: pale-yellow urine. Herbal tea and water-rich foods count too." },
      { topic: "sleep hygiene and getting better rest",
        text: "Sleep is where recovery happens. Anchor a consistent wake time, get morning daylight, and keep the room cool and dark. In the last hour: dim screens, no heavy meals or alcohol, and cut caffeine after about 2pm. A wind-down routine (stretching, reading, breathing) signals your body it's safe to power down. Most adults do best with 7–9 hours." },
      { topic: "stress management mindfulness and nervous system regulation",
        text: "Chronic stress shows up as poor sleep, cravings, and tight digestion. Reset your nervous system with slow breathing (try 4 in, 6 out for two minutes), a short walk outside, or 10 minutes of stillness. Name what's in your control, protect one screen-free pocket a day, and lean on connection. If anxiety is constant or overwhelming, a therapist can help — that's strength, not weakness." },
      { topic: "starting an exercise routine and staying consistent",
        text: "The best routine is the one you'll repeat. Start with three sessions a week you can actually keep, mix strength and movement you enjoy, and progress slowly (a little more weight, reps, or time each week). Schedule it like an appointment, lay out clothes the night before, and treat a missed day as data, not failure. Consistency compounds." },
      { topic: "strength training basics for beginners",
        text: "Strength training builds muscle, bone, and metabolism. Cover the basics twice a week: a squat or sit-to-stand, a hinge (deadlift/hip-hinge), a push (press or push-up), a pull (row), and a carry. Start light, own your form, and add load only when reps feel smooth. Two to three sets of 8–12 reps is a solid starting range. Rest days are part of the program." },
      { topic: "cardio heart health and movement for energy",
        text: "Aim for about 150 minutes of moderate movement a week — brisk walks, cycling, swimming, dancing — plus a couple of strength sessions. Movement lifts mood, steadies blood sugar, and protects your heart. If you're short on time, even three 10-minute walks add up, and a post-meal walk blunts glucose spikes." },
      { topic: "recovery rest days and avoiding overtraining",
        text: "Gains are made in recovery, not just the gym. Signs you need a rest day: lingering soreness, poor sleep, a higher resting heart rate, low mood, or stalled progress. Honor 1–2 lighter or off days a week, prioritize protein and sleep, and use active recovery (walking, mobility, stretching). Pushing through real fatigue raises injury risk and slows results." },
      { topic: "weight loss fat loss and a sustainable calorie deficit",
        text: "Sustainable fat loss comes from a modest calorie deficit you can live with — often 300–500 below maintenance — paired with enough protein and strength work to keep muscle. Favor whole foods that fill you up, expect the scale to zig-zag with water and hormones, and judge progress over weeks, not days. Crash diets backfire; small, repeatable habits win." },
      { topic: "understanding BMI and what the number means",
        text: "BMI is a quick screen of weight relative to height, not a verdict on health — it can't tell muscle from fat or account for build. Use it as one data point alongside how you feel, your energy, strength, waist trend, and lab work from your clinician. Trends over time tell you far more than a single reading." },
      { topic: "blood pressure heart rate and healthy vitals lifestyle",
        text: "Lifestyle moves the needle on blood pressure: regular movement, less sodium and ultra-processed food, more potassium-rich plants, good sleep, limited alcohol, and stress care. A resting heart rate that drifts down over weeks often signals improving fitness. Log readings at the same time of day. Consistently high blood pressure should be reviewed with your clinician — never stop prescribed medication on your own." },
      { topic: "building healthy habits and keeping a streak going",
        text: "Habits stick when they're small and anchored. Attach the new habit to something you already do ('after coffee, I stretch'), make it tiny enough to be laughable, and track it so you can see the streak. Don't break the chain twice in a row. Design your environment for the default you want, and celebrate showing up — identity ('I'm someone who moves daily') beats willpower." },
      { topic: "meal planning prep and eating well on a busy schedule",
        text: "A little prep removes the daily decision tax. Pick a handful of go-to meals, batch a protein and a grain, pre-cut veggies, and keep fast backups (eggs, canned beans, frozen produce, Greek yogurt) on hand. Build a plate template instead of counting everything: protein + plants + smart carb + healthy fat. Planning beats willpower at 7pm." },
      { topic: "sea moss superfoods and supplements",
        text: "Whole foods come first; supplements fill gaps, they don't replace meals. Sea moss is a mineral-rich seaweed people use for trace minerals and as a smoothie or gel base — treat it as a nourishing food, start small, and choose tested sources. Be cautious with iodine if you have thyroid issues, and run any new supplement past your clinician, especially alongside medications." },
      { topic: "energy fatigue and beating the afternoon slump",
        text: "Steady energy is built, not summoned. Protect sleep, eat balanced meals (protein + fiber, not sugar spikes), hydrate, and get morning daylight to set your rhythm. For the 3pm dip, take a brisk five-minute walk, step into sunlight, and have water before reaching for caffeine or sweets. Persistent exhaustion despite good basics is worth a clinician's review." },
      { topic: "mental health low mood and emotional wellbeing",
        text: "Mood and the body are linked — movement, sleep, sunlight, nutrition, and connection are real levers. Start with one gentle thing today: a walk, a text to a friend, ten minutes outside. Be as kind to yourself as you'd be to a friend. If low mood lingers for weeks, steals your interest in things, or feels heavy, please reach out to a mental-health professional. If you ever think about harming yourself, call or text 988 right away." },
      { topic: "motivation getting back on track after falling off",
        text: "Falling off is part of the process, not the end of it — the people who succeed are simply the ones who restart fastest. Skip the all-or-nothing guilt, shrink the next step until it's easy, and just take it: one walk, one balanced meal, one early night. Your streak resets, not your worth. Recommit to the next action, not the lost week." }
    ].freeze

    # Minimum cosine similarity for a query to count as a real KB hit. Tuned so
    # specific wellness questions match but vague chatter ("what's up") does not.
    THRESHOLD = 0.16

    # Common filler/function words stripped when deciding whether a query is
    # specific enough to answer from the KB at all.
    STOPWORDS = %w[
      the a an and or but is are was were be been being do does did to of in on at
      for with about it its this that what whats how why when where who whom
      my me i you your we our they them he she his her near around get got
      going gonna want need know tell show give please hey hi ok okay help
      thing things stuff lot some any much many right now today here there
    ].freeze

    module_function

    # Prefer the real embedding model (all-MiniLM-L6-v2) when it's available;
    # otherwise fall back to the dependency-free hashing retriever. Both expose
    # the same #add/#search/#threshold API so the rest of this module is agnostic.
    def retriever
      @retriever ||= begin
        r = build_retriever
        ENTRIES.each_with_index { |e, i| r.add(i, "#{e[:topic]} #{e[:topic]} #{e[:text]}") }
        r
      end
    end

    def build_retriever
      Sage::Embeddings.available? ? Sage::SemanticRetriever.new : Sage::Retriever.new
    end

    # Drop the memoized retriever so a newly-available (or stubbed) embedder is
    # picked up — used by the model warmup and tests.
    def reset!
      @retriever = nil
    end

    # => [{ entry:, score: }, ...]
    def search(query, limit: 3)
      retriever.search(query, limit: limit).map { |(i, score)| { entry: ENTRIES[i], score: score } }
    end

    # Best vetted answer for a free-form query, or nil if the query is too vague
    # or nothing is relevant enough (so callers fall back to their own default).
    def answer(query)
      return nil if content_tokens(query).size < 2 # too vague to safely match

      best = search(query, limit: 1).first
      cutoff = retriever.respond_to?(:threshold) ? retriever.threshold : THRESHOLD
      best && best[:score] >= cutoff ? best[:entry][:text] : nil
    end

    def content_tokens(query)
      query.to_s.downcase.scan(/[a-z]+/).reject { |w| w.length < 3 || STOPWORDS.include?(w) }
    end
  end
end
