# A bookable service offered by Holistic Wellness Fitness
# (personal training, nutrition, pelvic health, boxing, kids athletics, …).
class Service < ApplicationRecord
  has_many :appointments, dependent: :restrict_with_error

  CATEGORIES = [
    "Personal Training", "Nutrition", "Pelvic Health", "Boxing",
    "Kids Athletic Training", "Holistic Coaching"
  ].freeze

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :set_slug, on: :create

  scope :active,   -> { where(active: true) }
  scope :ordered,  -> { order(:position, :name) }
  scope :in_category, ->(c) { where(category: c) if c.present? }

  def price
    return "Free" if price_cents.to_i.zero?

    format("$%.0f", price_cents / 100.0)
  end

  def icon_name
    icon.presence || "fa-calendar-check"
  end

  def accent
    color.presence || "#4a7c59"
  end

  def to_param
    slug
  end

  private

  def set_slug
    self.slug = name.to_s.parameterize if slug.blank?
  end
end
