# A daily wellness check-in — the chart's vitals flowsheet entry.
class Checkin < ApplicationRecord
  belongs_to :user

  SCALE = (1..5)
  MOOD_LABELS   = { 1 => "Struggling", 2 => "Low", 3 => "Okay", 4 => "Good", 5 => "Thriving" }.freeze
  ENERGY_LABELS = { 1 => "Drained", 2 => "Sluggish", 3 => "Steady", 4 => "Energized", 5 => "Vibrant" }.freeze
  STRESS_LABELS = { 1 => "Calm", 2 => "Relaxed", 3 => "Moderate", 4 => "Tense", 5 => "Overwhelmed" }.freeze

  validates :checkin_date, presence: true,
                           uniqueness: { scope: :user_id, message: "already has a check-in" }
  validates :mood, :energy, :stress,
            inclusion: { in: SCALE, message: "must be 1–5" }, allow_nil: true
  validates :sleep_hours, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 24 }, allow_nil: true
  validates :water_oz, :resting_hr, :systolic, :diastolic, :weight,
            numericality: { greater_than: 0 }, allow_nil: true

  scope :recent, -> { order(checkin_date: :desc, id: :desc) }
  scope :chronological, -> { order(checkin_date: :asc, id: :asc) }

  def mood_label   = MOOD_LABELS[mood]
  def energy_label = ENERGY_LABELS[energy]
  def stress_label = STRESS_LABELS[stress]

  def blood_pressure
    return nil unless systolic && diastolic

    "#{systolic}/#{diastolic}"
  end

  # Simple AHA-style banding for the recorded blood pressure.
  def bp_category
    return nil unless systolic && diastolic

    if systolic < 120 && diastolic < 80 then "Normal"
    elsif systolic < 130 && diastolic < 80 then "Elevated"
    elsif systolic < 140 || diastolic < 90 then "Stage 1"
    else "Stage 2"
    end
  end

  # A composite 0–100 wellness score from the subjective scales + sleep.
  def wellness_score
    parts = []
    parts << mood   if mood
    parts << energy if energy
    parts << (6 - stress) if stress # invert: calmer is better
    parts << [ (sleep_hours.to_f / 8 * 5), 5 ].min if sleep_hours
    return nil if parts.empty?

    ((parts.sum.to_f / (parts.size * 5)) * 100).round
  end
end
