# A curated workout/video in the fitness library (shared, not member-owned).
class Workout < ApplicationRecord
  has_many :routine_items, dependent: :destroy
  has_many :routines, through: :routine_items

  CATEGORIES = %w[Strength Cardio HIIT Yoga Pilates Mobility Recovery].freeze
  LEVELS     = %w[Beginner Intermediate Advanced].freeze

  validates :title, presence: true
  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true
  validates :level, inclusion: { in: LEVELS }, allow_blank: true

  scope :by_category, ->(c) { where(category: c) if c.present? }

  def instructor_name
    instructor.presence || "Holistic Wellness Fitness"
  end

  # Pull the YouTube id out of any common URL form.
  def youtube_id
    return nil if video_url.blank?

    if (m = video_url.match(%r{(?:youtu\.be/|v=|embed/)([\w-]{11})}))
      m[1]
    end
  end

  def embed_url
    id = youtube_id
    id && "https://www.youtube.com/embed/#{id}"
  end

  def thumbnail_url
    id = youtube_id
    id && "https://i.ytimg.com/vi/#{id}/hqdefault.jpg"
  end
end
