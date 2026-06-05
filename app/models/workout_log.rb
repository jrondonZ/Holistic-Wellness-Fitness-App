# A logged training session — the chart's fitness activity entry.
class WorkoutLog < ApplicationRecord
  belongs_to :user
  belongs_to :workout, optional: true

  INTENSITIES = %w[Low Moderate High].freeze

  validates :performed_on, presence: true
  validates :activity, presence: true
  validates :duration_min, numericality: { greater_than: 0 }, allow_nil: true
  validates :calories_burned, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :intensity, inclusion: { in: INTENSITIES }, allow_blank: true

  scope :recent,    -> { order(performed_on: :desc, id: :desc) }
  scope :this_week, -> { where(performed_on: Date.current.beginning_of_week..) }

  def intensity_rank
    INTENSITIES.index(intensity) || 0
  end
end
