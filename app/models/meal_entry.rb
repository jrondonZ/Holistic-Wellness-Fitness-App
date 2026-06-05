# A single logged meal — the chart's nutrition log entry.
class MealEntry < ApplicationRecord
  belongs_to :user

  MEAL_TYPES = %w[Breakfast Lunch Dinner Snack].freeze

  validates :consumed_on, presence: true
  validates :name, presence: true
  validates :meal_type, inclusion: { in: MEAL_TYPES }
  validates :calories, :protein_g, :carbs_g, :fat_g,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :recent,   -> { order(consumed_on: :desc, id: :desc) }
  scope :for_date, ->(date) { where(consumed_on: date) }

  # Order meals the way a day actually runs.
  def self.meal_order
    MEAL_TYPES.each_with_index.to_h
  end

  def sort_key
    [ consumed_on, self.class.meal_order.fetch(meal_type, 99) ]
  end
end
