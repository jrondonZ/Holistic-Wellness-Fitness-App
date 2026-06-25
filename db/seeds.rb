# frozen_string_literal: true

#
# Seeds the Holistic Chart with a curated library (fitness videos, routines,
# education articles) and a fully-populated demo member so the chart comes to
# life immediately. Safe to run repeatedly (idempotent).

puts "🌱 Seeding Holistic Chart…"

# --------------------------------------------------------------- Fitness library
workouts = [
  # Strength — Pamela Reif
  { title: "Full Body Strength — Beginner", category: "Strength", level: "Beginner", duration_min: 20, calories_est: 160,
    equipment: "Mat", focus_area: "Full body", instructor: "Pamela Reif",
    video_url: "https://www.youtube.com/watch?v=UItWltVZZmE",
    summary: "An approachable, no-equipment full-body strength session to build a foundation.",
    description: "A controlled, beginner-friendly full body workout. Move with your breath and rest whenever you need — consistency beats intensity." },
  { title: "Full Body Strength — Intense", category: "Strength", level: "Advanced", duration_min: 20, calories_est: 220,
    equipment: "Mat", focus_area: "Full body", instructor: "Pamela Reif",
    video_url: "https://www.youtube.com/watch?v=Y2eOW7XYWxc",
    summary: "A challenging no-equipment full-body burner for stronger days.",
    description: "Turn up the intensity with this advanced full body flow. Keep your core engaged and your movements clean." },
  { title: "Upper Body with Weights", category: "Strength", level: "Intermediate", duration_min: 15, calories_est: 120,
    equipment: "Dumbbells", focus_area: "Arms, back & chest", instructor: "Pamela Reif",
    video_url: "https://www.youtube.com/watch?v=ATypGbs98F4",
    summary: "Sculpt the arms, back and chest with light dumbbells.",
    description: "Grab a pair of light dumbbells (or water bottles) and build upper-body strength and posture." },
  { title: "Core & Abs with Weights", category: "Strength", level: "Intermediate", duration_min: 10, calories_est: 90,
    equipment: "Dumbbell", focus_area: "Core", instructor: "Pamela Reif",
    video_url: "https://www.youtube.com/watch?v=cLO4uRh4xDE",
    summary: "Ten focused minutes for a strong, stable core.",
    description: "A short, potent core session. A strong core supports digestion, posture and every other movement you do." },

  # HIIT
  { title: "40-Min Full Body HIIT", category: "HIIT", level: "Advanced", duration_min: 40, calories_est: 400,
    equipment: "None", focus_area: "Full body", instructor: "SHEILA",
    video_url: "https://www.youtube.com/watch?v=Cc9Eelzd6wQ",
    summary: "A full 40-minute no-equipment HIIT to torch calories.",
    description: "High intensity intervals for cardiovascular fitness and calorie burn. Hydrate well and listen to your body." },
  { title: "30-Min Standing HIIT", category: "HIIT", level: "Intermediate", duration_min: 30, calories_est: 300,
    equipment: "None", focus_area: "Full body", instructor: "growwithjo",
    video_url: "https://www.youtube.com/watch?v=Ij2NtOL66rU",
    summary: "All-standing, joint-friendly HIIT — no floor work.",
    description: "Get your heart rate up without getting on the floor. Great for small spaces and busy mornings." },
  { title: "25-Min Beginner HIIT", category: "HIIT", level: "Beginner", duration_min: 25, calories_est: 220,
    equipment: "None", focus_area: "Full body", instructor: "MrandMrsMuscle",
    video_url: "https://www.youtube.com/watch?v=cbKkB3POqaY",
    summary: "An accessible entry point into interval training.",
    description: "Build cardio capacity gradually with this beginner-friendly, no-repeat HIIT." },

  # Cardio
  { title: "Indoor Walking Cardio", category: "Cardio", level: "Beginner", duration_min: 30, calories_est: 180,
    equipment: "None", focus_area: "Heart health", instructor: "Fabulous50s",
    video_url: "https://www.youtube.com/watch?v=NjfYo0YOVas",
    summary: "Low-impact, fat-burning indoor walk for any fitness level.",
    description: "A gentle, joyful walking workout that's kind to your joints while getting your steps in." },
  { title: "Walk + Cardio Intervals", category: "Cardio", level: "Beginner", duration_min: 30, calories_est: 200,
    equipment: "None", focus_area: "Heart health", instructor: "Rick Bhullar",
    video_url: "https://www.youtube.com/watch?v=zc56U8K6mhc",
    summary: "Walking with light cardio bursts to lift your heart rate.",
    description: "Alternate easy walking with gentle cardio intervals for an effective low-impact session." },
  { title: "Low-Impact Cardio", category: "Cardio", level: "Intermediate", duration_min: 30, calories_est: 240,
    equipment: "None", focus_area: "Conditioning", instructor: "Body Project",
    video_url: "https://www.youtube.com/watch?v=50kH47ZztHs",
    summary: "Steady low-impact cardio you can sustain.",
    description: "A balanced, no-jumping cardio workout for steady conditioning and mood-boosting movement." },

  # Yoga — Yoga With Adriene
  { title: "Yoga for Complete Beginners", category: "Yoga", level: "Beginner", duration_min: 20, calories_est: 70,
    equipment: "Mat", focus_area: "Mind & body", instructor: "Yoga With Adriene",
    video_url: "https://www.youtube.com/watch?v=v7AYKMP6rOE",
    summary: "The perfect first step onto the mat.",
    description: "Adriene welcomes complete beginners with a gentle, foundational practice to connect breath and body." },
  { title: "Yoga for Beginners — The Basics", category: "Yoga", level: "Beginner", duration_min: 22, calories_est: 75,
    equipment: "Mat", focus_area: "Mind & body", instructor: "Yoga With Adriene",
    video_url: "https://www.youtube.com/watch?v=pWobp3phsEU",
    summary: "Learn the building blocks of a home yoga practice.",
    description: "A calm, instructional flow covering the basics so you can practice with confidence." },

  # Pilates
  { title: "Gentle Pilates Flow", category: "Pilates", level: "Beginner", duration_min: 20, calories_est: 110,
    equipment: "Mat", focus_area: "Core & control", instructor: "Move With Nicole",
    video_url: "https://www.youtube.com/watch?v=PJLN1kAzbyw",
    summary: "A soft, controlled mat Pilates flow for core strength.",
    description: "Slow, mindful Pilates to build deep core strength, stability and body awareness." },

  # Mobility
  { title: "Full Body Stretch & Mobility", category: "Mobility", level: "Beginner", duration_min: 20, calories_est: 60,
    equipment: "Mat", focus_area: "Flexibility", instructor: "MrandMrsMuscle",
    video_url: "https://www.youtube.com/watch?v=DppDOK2SvP0",
    summary: "Release tension and move pain-free.",
    description: "A follow-along stretch and mobility routine to ease stiffness and restore range of motion." },
  { title: "Flexibility & Mobility Routine", category: "Mobility", level: "Intermediate", duration_min: 20, calories_est: 65,
    equipment: "Mat", focus_area: "Flexibility", instructor: "Nuzzo",
    video_url: "https://www.youtube.com/watch?v=iNkR5nQFa3E",
    summary: "Improve flexibility from beginner to advanced.",
    description: "A daily-friendly flexibility and mobility flow you can return to again and again." },

  # Recovery
  { title: "Rest Day Active Recovery", category: "Recovery", level: "Beginner", duration_min: 20, calories_est: 55,
    equipment: "Mat", focus_area: "Recovery", instructor: "MrandMrsMuscle",
    video_url: "https://www.youtube.com/watch?v=3yA3PNcILlc",
    summary: "Gentle movement to recover and recharge.",
    description: "Keep your body moving on rest days with low-intensity mobility that supports recovery." },
  { title: "Morning Mobility Wake-Up", category: "Recovery", level: "Beginner", duration_min: 10, calories_est: 35,
    equipment: "None", focus_area: "Recovery", instructor: "Nuzzo",
    video_url: "https://www.youtube.com/watch?v=0VrLgzwTmTg",
    summary: "Ten gentle minutes to start the day grounded.",
    description: "A short morning mobility routine to wake up the joints and set a calm tone for the day." }
]

workouts.each do |attrs|
  w = Workout.find_or_initialize_by(title: attrs[:title])
  w.update!(attrs)
end
puts "  • #{Workout.count} workouts in the library"

# --------------------------------------------------------------------- Routines
def routine_with_items!(title:, attrs:, items:)
  routine = Routine.find_or_initialize_by(title: title)
  routine.update!(attrs)
  routine.routine_items.destroy_all
  items.each_with_index do |(workout_title, day_label, notes), i|
    workout = Workout.find_by(title: workout_title)
    next unless workout

    routine.routine_items.create!(workout: workout, position: i + 1, day_label: day_label, notes: notes)
  end
  routine
end

routine_with_items!(
  title: "Reset & Restore — Foundations",
  attrs: { goal: "General wellness", level: "Beginner", focus: "Whole-body balance",
           days_per_week: 4, duration_weeks: 4,
           summary: "A gentle 4-week on-ramp blending movement, mobility and calm.",
           description: "Designed for fresh starts. Four sessions a week mix gentle strength, walking, Pilates and mobility so you build the habit without burning out.\n\nRepeat the week, adding a little more each time. Pair it with daily check-ins to feel the difference." },
  items: [
    [ "Yoga for Complete Beginners", "Day 1 · Mind & body", "Ease in gently" ],
    [ "Indoor Walking Cardio", "Day 2 · Cardio", "Keep it conversational" ],
    [ "Gentle Pilates Flow", "Day 3 · Core", "Focus on control" ],
    [ "Full Body Stretch & Mobility", "Day 4 · Mobility", "Unwind and restore" ]
  ]
)

routine_with_items!(
  title: "Strong & Balanced — Build",
  attrs: { goal: "Build strength", level: "Intermediate", focus: "Strength & stability",
           days_per_week: 5, duration_weeks: 6,
           summary: "Six weeks to build real, balanced strength with recovery built in.",
           description: "A progressive strength block balanced with mobility and recovery so you build muscle without overtraining.\n\nProgress the intensity each fortnight and keep logging your sessions to watch the trend climb." },
  items: [
    [ "Full Body Strength — Beginner", "Day 1 · Full body", "Quality reps" ],
    [ "Upper Body with Weights", "Day 2 · Upper", "Light dumbbells" ],
    [ "30-Min Standing HIIT", "Day 3 · Conditioning", "Joint-friendly" ],
    [ "Core & Abs with Weights", "Day 4 · Core", "Brace the core" ],
    [ "Rest Day Active Recovery", "Day 5 · Recovery", "Move and breathe" ]
  ]
)

routine_with_items!(
  title: "Gut-Friendly Burn",
  attrs: { goal: "Weight loss", level: "Intermediate", focus: "Sustainable fat loss",
           days_per_week: 4, duration_weeks: 4,
           summary: "Four weeks of joint-kind cardio and intervals, paired with restorative days.",
           description: "Sustainable fat loss favors consistency over punishment. This block keeps intensity moderate and recovery generous so your gut and nervous system stay happy.\n\nFuel with whole foods and hydrate well — the nutrition log will help." },
  items: [
    [ "25-Min Beginner HIIT", "Day 1 · Intervals", "Build gradually" ],
    [ "Low-Impact Cardio", "Day 2 · Cardio", "Steady effort" ],
    [ "Full Body Stretch & Mobility", "Day 3 · Mobility", "Active recovery" ],
    [ "Yoga for Beginners — The Basics", "Day 4 · Restore", "Calm the system" ]
  ]
)
puts "  • #{Routine.count} routines (#{RoutineItem.count} sessions)"

# -------------------------------------------------------------------- Education
articles = [
  { title: "The Gut–Brain Axis: Why Digestion Shapes Your Mood",
    category: "Gut Health", read_minutes: 5, hero_color: "#4a7c59", published_on: Date.current - 6,
    summary: "Your gut and brain are in constant conversation. Here's how nurturing one nourishes the other.",
    body: "Your gut is often called your \"second brain\" — and for good reason. Millions of neurons line the digestive tract, in constant dialogue with the brain through the vagus nerve.\n\n## The conversation\nThis two-way street means stress can upset digestion, and an inflamed gut can cloud mood and energy. Around 90% of the body's serotonin — a key mood molecule — is produced in the gut.\n\n## Nurturing the axis\nFiber-rich plants feed beneficial bacteria. Fermented foods add diversity. Slow, mindful eating signals safety to the nervous system. Even a short walk after meals supports motility.\n\n## The holistic takeaway\nWhen we care for the gut, we're also caring for mood, focus and resilience. Track how meals make you feel in your chart — patterns reveal themselves quickly." },

  { title: "Sea Moss: Nature's Mineral-Rich Multivitamin",
    category: "Sea Moss", read_minutes: 4, hero_color: "#2d4a30", published_on: Date.current - 12,
    summary: "Wildcrafted sea moss is prized for its minerals and gut-soothing properties. A grounded look.",
    body: "Sea moss (Chondrus crispus) is a red algae harvested from the ocean, traditionally used across the Caribbean and beyond.\n\n## Why people love it\nIt's naturally rich in minerals and trace elements, and its gel-like texture comes from carrageenan, a soluble fiber that can soothe the digestive tract.\n\n## How to use it\nA spoonful of gel blends easily into smoothies, teas or oatmeal. Start small and listen to your body.\n\n## A balanced view\nSea moss is a supplement, not a miracle. It works best inside a varied, whole-food diet. As always, check with your clinician — especially regarding thyroid and iodine intake." },

  { title: "Strength Training Isn't Just for the Gym",
    category: "Movement", read_minutes: 5, hero_color: "#a3b18a", published_on: Date.current - 3,
    summary: "Building muscle protects metabolism, bones and independence — and you can start at home.",
    body: "Muscle is metabolic gold. It burns energy at rest, stabilizes blood sugar and protects your bones and joints as you age.\n\n## You don't need a gym\nBodyweight squats, push-ups against a counter, and light dumbbells are enough to begin. Two to three short sessions a week create real change.\n\n## Progress gently\nThe principle is simple: do a little more over time. Add a rep, slow the tempo, or reach for slightly heavier weights.\n\n## Recovery is part of training\nMuscle grows during rest. Sleep, protein and mobility days aren't optional extras — they're where the adaptation happens." },

  { title: "Sleep: The Most Underrated Wellness Tool",
    category: "Sleep", read_minutes: 4, hero_color: "#6b6b6b", published_on: Date.current - 9,
    summary: "No supplement rivals a good night's sleep. Small rituals make a big difference.",
    body: "Sleep is when the body repairs tissue, consolidates memory and rebalances hormones that govern hunger and stress.\n\n## Signs you need more\nAfternoon energy crashes, sugar cravings and short temper often trace back to short or fragmented sleep.\n\n## Build a wind-down\nDim the lights an hour before bed, keep screens away, and let the room run cool. A consistent sleep and wake time is more powerful than any gadget.\n\n## Track it\nLog your sleep hours in each check-in. Over a few weeks you'll see how rest connects to mood, cravings and workout quality." },

  { title: "Mindful Eating: Slowing Down to Heal",
    category: "Nutrition", read_minutes: 4, hero_color: "#c9a96e", published_on: Date.current - 1,
    summary: "How you eat matters as much as what you eat. Presence changes digestion.",
    body: "Mindful eating is the practice of bringing full attention to your meals — and it's one of the gentlest ways to improve digestion and your relationship with food.\n\n## Why it works\nEating in a rushed, stressed state shifts the body into \"fight or flight,\" which slows digestion. Slowing down activates \"rest and digest.\"\n\n## Simple practices\nPut the fork down between bites. Notice color, texture and flavor. Pause halfway and ask how hungry you still are.\n\n## The ripple effect\nPeople who eat mindfully often naturally eat enough — no rigid rules required. Log meals in your chart to stay aware without obsessing." },

  { title: "Breath & Stress: Your Built-In Reset Button",
    category: "Mindfulness", read_minutes: 3, hero_color: "#4a7c59", published_on: Date.current - 15,
    summary: "A few minutes of slow breathing can shift your whole nervous system.",
    body: "When stress spikes, breathing becomes shallow and fast. The good news: you can reverse the signal consciously.\n\n## The physiology\nSlow, extended exhales stimulate the vagus nerve, nudging the body toward calm. This lowers heart rate and eases tension.\n\n## Try this\nInhale for a count of four, exhale for a count of six. Repeat for two minutes. That's it.\n\n## Make it a habit\nPair breathwork with your evening check-in. Watch your stress scores soften over time — proof that small practices compound." }
]

articles.each do |attrs|
  a = Article.find_or_initialize_by(title: attrs[:title])
  a.update!(attrs.merge(author: "Celine Bonilla, RN"))
end
puts "  • #{Article.count} education articles"

# ------------------------------------------------------------------ Demo member
demo = User.find_or_initialize_by(username: "demo")
if demo.new_record?
  demo.assign_attributes(
    first_name: "Jordan", last_name: "Rivera", email: "demo@holisticchart.com",
    password: "wellness", password_confirmation: "wellness"
  )
  demo.save!
  puts "  • Created demo member (username: demo / password: wellness)"
end

demo.ensure_health_profile
demo.health_profile.update!(
  date_of_birth: Date.new(1991, 4, 18), sex: "Non-binary", height_in: 67,
  starting_weight: 185, goal_weight: 160, activity_level: "Moderately active",
  dietary_preference: "Gut-healing", blood_type: "O+", primary_goal: "Gut healing",
  coach_name: "Celine Bonilla, RN", emergency_contact: "Sam Rivera · 203-555-0142",
  allergies: "Gluten, excess dairy", conditions: "Working on digestion & sustainable energy."
)

# Generate ~30 days of living history (only once, to stay idempotent).
if demo.checkins.none?
  breakfasts = [ [ "Sea moss smoothie bowl", 380, 18, 52, 10 ], [ "Oats with berries & chia", 340, 12, 55, 8 ],
                 [ "Veggie scramble & avocado", 420, 24, 14, 28 ], [ "Greek yogurt & walnuts", 300, 22, 24, 14 ] ]
  lunches    = [ [ "Quinoa & roasted veggie bowl", 520, 20, 68, 16 ], [ "Lentil & kale soup", 410, 22, 52, 10 ],
                 [ "Grilled salmon salad", 480, 34, 18, 28 ], [ "Chickpea wrap", 500, 19, 60, 18 ] ]
  dinners    = [ [ "Baked cod & sweet potato", 540, 38, 46, 16 ], [ "Stir-fry tofu & brown rice", 560, 26, 70, 18 ],
                 [ "Turkey chili", 520, 36, 40, 18 ], [ "Roasted chicken & greens", 500, 40, 22, 22 ] ]
  snacks     = [ [ "Apple & almond butter", 210, 6, 24, 12 ], [ "Hummus & carrots", 180, 6, 22, 8 ],
                 [ "Handful of nuts", 200, 7, 8, 17 ], [ "Herbal tea & dark chocolate", 120, 2, 14, 7 ] ]
  logged_workouts = Workout.where(title: [
    "Yoga for Complete Beginners", "Indoor Walking Cardio", "Full Body Strength — Beginner",
    "25-Min Beginner HIIT", "Gentle Pilates Flow", "Full Body Stretch & Mobility", "Low-Impact Cardio"
  ]).to_a

  weight = 185.0
  (0..29).to_a.reverse_each do |days_ago|
    date = Date.current - days_ago
    # Skip a couple of days so the streak/flowsheet feels human.
    next if [ 8, 17, 23 ].include?(days_ago)

    weight -= rand(0.0..0.45)
    sleep = (6.0 + rand(0.0..2.5)).round(1)
    energy = [ [ (sleep > 7 ? 4 : 3) + rand(-1..1), 1 ].max, 5 ].min
    mood   = [ [ energy + rand(-1..1), 1 ].max, 5 ].min
    stress = [ [ 6 - energy + rand(-1..1), 1 ].max, 5 ].min

    demo.checkins.create!(
      checkin_date: date, mood: mood, energy: energy, stress: stress,
      sleep_hours: sleep, water_oz: [ 40, 48, 56, 64, 72 ].sample,
      weight: weight.round(1), resting_hr: rand(58..68),
      systolic: rand(112..124), diastolic: rand(72..80),
      notes: ([ "Felt strong today.", "Gut felt calm.", "A bit tired but pushed through.", nil ].sample)
    )

    # Nutrition for the most recent 16 days.
    if days_ago <= 15
      [ [ "Breakfast", breakfasts ], [ "Lunch", lunches ], [ "Dinner", dinners ] ].each do |meal_type, options|
        name, cals, p, c, f = options.sample
        demo.meal_entries.create!(consumed_on: date, meal_type: meal_type, name: name,
                                  calories: cals, protein_g: p, carbs_g: c, fat_g: f)
      end
      if rand < 0.7
        name, cals, p, c, f = snacks.sample
        demo.meal_entries.create!(consumed_on: date, meal_type: "Snack", name: name,
                                  calories: cals, protein_g: p, carbs_g: c, fat_g: f)
      end
    end

    # Workouts ~4x/week.
    if [ 1, 2, 4, 6 ].include?(date.wday) && rand < 0.85
      w = logged_workouts.sample
      demo.workout_logs.create!(
        performed_on: date, workout: w, activity: w&.title || "Movement",
        duration_min: w&.duration_min || 30, intensity: [ "Low", "Moderate", "High" ].sample,
        calories_burned: w&.calories_est || 200,
        notes: ([ "Felt good.", "Tough but worth it.", nil ].sample)
      )
    end
  end
  puts "  • Generated #{demo.checkins.count} check-ins, #{demo.meal_entries.count} meals, #{demo.workout_logs.count} workouts for the demo member"
end

# ------------------------------------------------------------------ Services
services = [
  { name: "Personal Training", category: "Personal Training", icon: "fa-dumbbell", color: "#4a7c59",
    duration_min: 60, price_cents: 7500, provider_name: "HWF Coaching Team", position: 1,
    tagline: "1:1 strength & conditioning tailored to your goals.",
    description: "Private personal training sessions built around your body and goals — strength, mobility, fat loss or performance. Every session is programmed and progressed by a certified coach." },
  { name: "Nutrition Coaching", category: "Nutrition", icon: "fa-bowl-food", color: "#c9a96e",
    duration_min: 45, price_cents: 9000, provider_name: "Celine Bonilla, RN", position: 2,
    tagline: "Holistic, gut-focused nutrition with a registered nurse.",
    description: "Personalized nutrition coaching rooted in whole foods and gut health. We'll review your logs, set realistic targets and build sustainable habits — no crash diets." },
  { name: "Pelvic Health Therapy", category: "Pelvic Health", icon: "fa-heart-circle-check", color: "#a3b18a",
    duration_min: 50, price_cents: 11000, provider_name: "Pelvic Health Specialist", position: 3,
    tagline: "Specialized support for core & pelvic floor health.",
    description: "Compassionate, evidence-based pelvic floor therapy — pre/postnatal recovery, core retraining and pelvic health education in a private, supportive setting." },
  { name: "Boxing & Conditioning", category: "Boxing", icon: "fa-hand-fist", color: "#2d4a30",
    duration_min: 60, price_cents: 6500, provider_name: "HWF Coaching Team", position: 4,
    tagline: "Technique, cardio and confidence on the pads.",
    description: "Non-contact boxing for fitness — footwork, combinations and conditioning that build cardiovascular fitness, coordination and stress relief for all levels." },
  { name: "Kids Athletic Training", category: "Kids Athletic Training", icon: "fa-child-reaching", color: "#6f9e58",
    duration_min: 45, price_cents: 5000, provider_name: "Youth Development Coach", position: 5,
    tagline: "Fun, age-appropriate athletic development for kids.",
    description: "Movement, speed, agility and coordination for young athletes — building confidence and fundamental skills through playful, structured sessions." },
  { name: "Pro Soccer Training", category: "Soccer Training", icon: "fa-futbol", color: "#2d4a30",
    duration_min: 75, price_cents: 8500, provider_name: "Pro Soccer Coach", position: 6,
    tagline: "Elite technical & tactical soccer development.",
    description: "Professional-level soccer training — ball mastery, finishing, first touch, speed, agility and game IQ. Built for competitive youth and adult players aiming to level up, with individualized drills and video-informed feedback." },
  { name: "Holistic Coaching Session", category: "Holistic Coaching", icon: "fa-spa", color: "#4a7c59",
    duration_min: 60, price_cents: 12000, provider_name: "Celine Bonilla, RN", position: 7,
    tagline: "Whole-self coaching: body, mind and gut.",
    description: "A deep-dive coaching session integrating nutrition, movement and mindfulness to reset balance, heal the gut and build lasting wellness habits." }
]
services.each do |attrs|
  Service.find_or_initialize_by(name: attrs[:name]).update!(attrs)
end
puts "  • #{Service.count} bookable services"

# ----------------------------------------------------------- HIPAA training
hipaa = TrainingModule.find_or_initialize_by(slug: "hipaa-privacy")
hipaa.update!(
  title: "HIPAA Privacy & Security Awareness",
  version: "2026.1", minutes: 12, required: true, position: 1,
  summary: "Understand how we protect your health information and your rights under HIPAA.",
  body: <<~BODY,
    Holistic Wellness Fitness is committed to protecting your Protected Health Information (PHI). This short training explains what HIPAA means for you and for our team.

    ## What is PHI?
    Protected Health Information is any information that can identify you and relates to your health, care or payment for care — your name, contact details, vitals, check-ins, assessments and appointment history all count.

    ## Your rights
    Under HIPAA you have the right to access your records, request corrections, know who we share information with, and ask us to restrict certain uses. Your chart is yours.

    ## How we protect your information
    We limit access to your PHI to the care team directly involved in your wellness. Information is transmitted over encrypted connections, protected by individual logins, and never sold. Messages in your chart stay between you and the care team.

    ## Your responsibilities
    Keep your password private, sign out on shared devices, and let us know immediately if you suspect unauthorized access to your account. Together we keep your information safe.
  BODY
  quiz: [
    { "q" => "What does PHI stand for?",
      "options" => [ "Personal Health Insurance", "Protected Health Information", "Private Health Index" ],
      "answer" => 1 },
    { "q" => "Who can access your chart's health information?",
      "options" => [ "Anyone with the link", "Only the care team involved in your wellness", "All members" ],
      "answer" => 1 },
    { "q" => "Which is a good way to protect your PHI?",
      "options" => [ "Share your password with a friend", "Sign out on shared devices", "Post your vitals publicly" ],
      "answer" => 1 },
    { "q" => "Under HIPAA, you have the right to…",
      "options" => [ "Access and correct your records", "Nothing — records are private from you", "Only view records once a year" ],
      "answer" => 0 }
  ]
)
puts "  • HIPAA training module ready (#{hipaa.questions.size}-question quiz)"

# ------------------------------------------------------------------- Admin
admin = User.find_or_initialize_by(username: "celine")
if admin.new_record?
  admin.assign_attributes(
    first_name: "Celine", last_name: "Bonilla", email: "celine@holisticwellnessandfitness.com",
    password: "celine123", password_confirmation: "celine123", role: "admin",
    title: "Founder & Holistic Wellness Coach · RN",
    phone: "203-800-1118"
  )
  admin.save!
  puts "  • Created admin (username: celine / password: celine123)"
else
  admin.update!(role: "admin")
end

# ------------------------------------------------------------- Owner (top admin)
owner = User.find_or_initialize_by(username: "josiah")
if owner.new_record?
  owner.assign_attributes(
    first_name: "Josiah", last_name: "Rondon", email: "josiahrondon@gmail.com",
    password: "owner12345", password_confirmation: "owner12345", role: "owner",
    title: "Owner & Administrator", phone: "203-800-1118"
  )
  owner.save!
  puts "  • Created OWNER (username: josiah / password: owner12345)"
else
  owner.update!(role: "owner")
end

# A second admin/provider so members have a choice of who to message.
marcus = User.find_or_initialize_by(username: "marcus")
if marcus.new_record?
  marcus.assign_attributes(
    first_name: "Marcus", last_name: "Lee", email: "marcus@holisticwellnessandfitness.com",
    password: "coach12345", password_confirmation: "coach12345", role: "admin",
    title: "Personal Trainer & Boxing Coach", phone: "203-800-1120"
  )
  marcus.save!
  puts "  • Created admin/provider (username: marcus / password: coach12345)"
else
  marcus.update!(role: "admin")
end

# Pre-accept the current legal docs for seeded accounts so their demo logins
# skip the acceptance modal. (The owner is exempt; a new sign-up still sees it.)
[ demo, admin, marcus ].each(&:accept_legal!)
demo.complete_tutorial!

# Assign providers to the demo member so they can choose who to message.
[ [ admin, "Holistic Nutrition · RN" ], [ marcus, "Personal Trainer" ] ].each do |provider, specialty|
  CareAssignment.find_or_create_by!(member: demo, provider: provider) { |a| a.specialty = specialty }
end

# -------------------------------------------- Demo bookings, messages, notes
if demo.appointments.none?
  pt = Service.find_by(category: "Personal Training")
  nutrition = Service.find_by(category: "Nutrition")

  demo.appointments.create!(service: pt, scheduled_at: 3.days.from_now.change(hour: 17, min: 30),
                            status: "confirmed", mode: "virtual",
                            meeting_url: "https://meet.google.com/demo-hwf-session", confirmed_at: Time.current,
                            reason: "Progress check + lower-body strength.")
  demo.appointments.create!(service: nutrition, scheduled_at: 6.days.from_now.change(hour: 12, min: 0),
                            status: "requested", mode: "in_person",
                            reason: "Review nutrition logs and gut-healing plan.")
  # A completed past session (bypass the future-only guard used on booking).
  past = demo.appointments.create!(service: pt, scheduled_at: 5.days.from_now.change(hour: 9),
                                   status: "confirmed", mode: "in_person")
  past.update_columns(scheduled_at: 1.week.ago.change(hour: 9), status: "completed")
  puts "  • #{demo.appointments.count} demo appointments"
end

if demo.messages.none?
  convo = [
    [ admin, "Hi Jordan! Lovely progress this week 🎉 How are you feeling after the new routine?", 2.days.ago ],
    [ demo,  "Thanks Celine! Energy is up, but my sleep has been a little short lately.", 2.days.ago + 3.hours ],
    [ admin, "Let's build a wind-down routine — I'll add a note to your chart with a few ideas.", 1.day.ago ]
  ]
  convo.each do |sender, body, at|
    m = demo.messages.create!(sender: sender, provider: admin, body: body, topic: "General question")
    m.update_columns(created_at: at, updated_at: at, read_at: (sender == demo ? at : nil))
  end
  puts "  • Seeded a demo conversation"
end

if demo.notifications.none?
  Notification.notify(demo, kind: "appointment", icon: "fa-calendar-check",
                      title: "Appointment confirmed", body: "Personal Training · virtual", url: "/appointments")
  Notification.notify(demo, kind: "care", icon: "fa-user-doctor",
                      title: "Marcus Lee joined your care team", url: "/messages/#{marcus.id}")
  puts "  • Seeded demo notifications"
end

if demo.assessments.none?
  demo.assessments.create!(
    author: admin, title: "Sleep optimization", category: "Sleep", severity: "watch", status: "monitoring",
    summary: "Averaging ~6.5 hrs/night with dips in energy. Sleep is the likely lever for the recent energy and stress scores.",
    recommendations: "Consistent 10:30pm wind-down, screens off 60 min prior, and the Morning Mobility Wake-Up routine. Reassess in 2 weeks."
  )
  puts "  • Seeded a demo assessment"
end

# Mark HIPAA complete for the demo member so the flow shows a certificate.
demo.training_completions.find_or_create_by!(training_module: hipaa) do |tc|
  tc.acknowledged = true
  tc.signature = demo.full_name
  tc.score = 100
  tc.completed_at = 3.days.ago
end

puts "✅ Done."
puts "   Owner:    username josiah · password owner12345  (top admin)"
puts "   Provider: username celine · password celine123"
puts "   Provider: username marcus · password coach12345"
puts "   Member:   username demo   · password wellness"
