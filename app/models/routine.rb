# A multi-week program that strings curated workouts together.
class Routine < ApplicationRecord
  has_many :routine_items, -> { order(:position) }, dependent: :destroy
  has_many :workouts, through: :routine_items

  LEVELS = %w[Beginner Intermediate Advanced].freeze

  validates :title, presence: true

  scope :by_level, ->(l) { where(level: l) if l.present? }

  def total_minutes
    workouts.sum(:duration_min)
  end

  def session_count
    routine_items.size
  end
end
