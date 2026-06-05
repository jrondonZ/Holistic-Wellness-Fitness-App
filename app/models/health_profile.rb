# Demographics, baseline vitals and care goals — the header of the member chart.
class HealthProfile < ApplicationRecord
  belongs_to :user

  SEXES                = [ "Female", "Male", "Non-binary", "Prefer not to say" ].freeze
  ACTIVITY_LEVELS      = [ "Sedentary", "Lightly active", "Moderately active", "Very active", "Athlete" ].freeze
  ACTIVITY_FACTORS     = { "Sedentary" => 1.2, "Lightly active" => 1.375, "Moderately active" => 1.55,
                           "Very active" => 1.725, "Athlete" => 1.9 }.freeze
  DIETARY_PREFERENCES  = [ "Balanced", "Plant-based", "Vegetarian", "Vegan", "Pescatarian",
                           "Mediterranean", "Gluten-free", "Anti-inflammatory", "Gut-healing" ].freeze
  BLOOD_TYPES          = [ "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", "Unknown" ].freeze
  GOALS                = [ "Weight loss", "Gut healing", "Build strength", "Increase energy",
                           "Stress & balance", "General wellness" ].freeze

  validates :sex,            inclusion: { in: SEXES }, allow_blank: true
  validates :activity_level, inclusion: { in: ACTIVITY_LEVELS }, allow_blank: true
  validates :height_in,      numericality: { greater_than: 0, less_than: 100 }, allow_nil: true
  validates :starting_weight, :goal_weight,
            numericality: { greater_than: 0, less_than: 1500 }, allow_nil: true

  def coach
    coach_name.presence || "Celine Bonilla, RN"
  end

  def age
    return nil unless date_of_birth

    today = Date.current
    today.year - date_of_birth.year - (today.strftime("%m%d") < date_of_birth.strftime("%m%d") ? 1 : 0)
  end

  # Height stored in inches, shown as 5'7".
  def height_display
    return nil unless height_in

    feet, inches = height_in.to_i.divmod(12)
    "#{feet}'#{inches}\""
  end

  # Body Mass Index for a given weight (lbs) and the stored height (inches).
  def bmi(weight_lbs = user&.current_weight)
    return nil unless height_in.to_f.positive? && weight_lbs.to_f.positive?

    ((weight_lbs.to_f / (height_in.to_f**2)) * 703).round(1)
  end

  def bmi_category(weight_lbs = user&.current_weight)
    value = bmi(weight_lbs)
    return nil unless value

    case value
    when ...18.5 then "Underweight"
    when 18.5...25 then "Healthy"
    when 25...30 then "Overweight"
    else "Elevated"
    end
  end

  # Mifflin–St Jeor maintenance estimate (kcal/day) from height, weight, age, sex.
  def estimated_maintenance_calories(weight_lbs = user&.current_weight)
    return nil unless weight_lbs.to_f.positive? && height_in.to_f.positive? && age && sex.present?

    kg = weight_lbs.to_f * 0.45359
    cm = height_in.to_f * 2.54
    sex_offset = sex == "Male" ? 5 : -161
    bmr = (10 * kg) + (6.25 * cm) - (5 * age) + sex_offset
    (bmr * (ACTIVITY_FACTORS[activity_level] || 1.375)).round(-1).to_i
  end

  # Daily calorie target, nudged for a weight-loss goal.
  def target_calories(weight_lbs = user&.current_weight)
    base = estimated_maintenance_calories(weight_lbs)
    return 2000 unless base

    primary_goal == "Weight loss" ? base - 500 : base
  end

  # Progress toward the goal weight, as a 0–100 percentage.
  def goal_progress(current = user&.current_weight)
    return nil unless starting_weight && goal_weight && current

    total = (starting_weight - goal_weight).to_f
    return 100 if total.zero?

    done = (starting_weight - current).to_f
    [ [ (done / total * 100).round, 0 ].max, 100 ].min
  end
end
