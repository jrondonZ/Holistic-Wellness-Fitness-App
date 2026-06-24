# A direct message inside a member's conversation with the care team.
# Threads only ever exist between one member and the admin/care team.
class Message < ApplicationRecord
  belongs_to :member, class_name: "User", inverse_of: :messages
  belongs_to :sender, class_name: "User", inverse_of: :sent_messages

  TOPICS = [ "General question", "My appointments", "Nutrition", "Fitness & training",
             "Billing", "Technical help" ].freeze

  validates :body, presence: true, length: { maximum: 5000 }
  validates :topic, inclusion: { in: TOPICS }, allow_blank: true
  validate  :sender_is_member_or_staff

  scope :chronological, -> { order(:created_at) }
  scope :unread, -> { where(read_at: nil) }

  def from_admin?
    sender.staff?
  end

  def from_member?
    sender_id == member_id
  end

  def read?
    read_at.present?
  end

  private

  # Enforce that only the member themselves or a staff member can post.
  def sender_is_member_or_staff
    return if sender.blank? || member.blank?
    return if sender_id == member_id || sender.staff?

    errors.add(:sender, "must be the member or a care-team member")
  end
end
