# Joins a workout into a routine, in order, with a day label.
class RoutineItem < ApplicationRecord
  belongs_to :routine
  belongs_to :workout

  validates :position, numericality: { only_integer: true }, allow_nil: true
end
