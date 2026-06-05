# An education article on holistic wellness & fitness (shared library).
class Article < ApplicationRecord
  CATEGORIES = [ "Nutrition", "Gut Health", "Movement", "Mindfulness", "Sleep", "Sea Moss" ].freeze

  validates :title, presence: true
  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true

  scope :by_category, ->(c) { where(category: c) if c.present? }
  scope :newest, -> { order(published_on: :desc, id: :desc) }

  def author_name
    author.presence || "Celine Bonilla, RN"
  end

  def read_time
    minutes = read_minutes.presence || [ (body.to_s.split.size / 200.0).ceil, 1 ].max
    "#{minutes} min read"
  end

  # Split the body into paragraphs for rendering.
  def paragraphs
    body.to_s.split(/\n{2,}/).map(&:strip).reject(&:blank?)
  end

  def accent
    hero_color.presence || "#4a7c59"
  end
end
