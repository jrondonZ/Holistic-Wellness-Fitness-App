# A direct message inside a member's conversation with a specific provider.
# A thread is the pair (member, provider); messages may be authored by the
# member or by a staff member (sender).
class Message < ApplicationRecord
  belongs_to :member,   class_name: "User", inverse_of: :messages
  belongs_to :sender,   class_name: "User", inverse_of: :sent_messages
  belongs_to :provider, class_name: "User"

  TOPICS = [ "General question", "My appointments", "Nutrition", "Fitness & training",
             "Billing", "Technical help" ].freeze

  validates :body, presence: true, length: { maximum: 5000 }
  validates :topic, inclusion: { in: TOPICS }, allow_blank: true
  validate  :sender_is_member_or_staff
  validate  :provider_is_staff

  scope :chronological, -> { order(:created_at) }
  scope :unread, -> { where(read_at: nil) }
  scope :thread, ->(member, provider) { where(member_id: member, provider_id: provider) }

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

  # Only the member themselves or a staff member may post.
  def sender_is_member_or_staff
    return if sender.blank? || member.blank?
    return if sender_id == member_id || sender.staff?

    errors.add(:sender, "must be the member or a care-team member")
  end

  def provider_is_staff
    errors.add(:provider, "must be a staff member") unless provider&.staff?
  end
end
