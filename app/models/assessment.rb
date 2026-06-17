# A clinical note / assessment an admin records on a member's chart
# (the "help diagnose" tool). Visible to the member as care-team guidance.
class Assessment < ApplicationRecord
  belongs_to :member, class_name: "User", inverse_of: :assessments
  belongs_to :author, class_name: "User"

  SEVERITIES = %w[info watch concern urgent].freeze
  STATUSES   = %w[open monitoring resolved].freeze
  CATEGORIES = [
    "General", "Nutrition", "Cardiometabolic", "Musculoskeletal",
    "Mental wellness", "Sleep", "Gut health"
  ].freeze

  validates :title, presence: true
  validates :severity, inclusion: { in: SEVERITIES }
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }
  scope :open,   -> { where.not(status: "resolved") }

  def severity_tone
    case severity
    when "info" then "muted"
    when "watch" then "ok"
    when "concern", "urgent" then "low"
    else "muted"
    end
  end
end
