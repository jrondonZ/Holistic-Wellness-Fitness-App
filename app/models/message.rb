# A direct message inside a member's conversation with the clinic.
# Threads only ever exist between one member and the admin/care team.
class Message < ApplicationRecord
  belongs_to :member, class_name: "User", inverse_of: :messages
  belongs_to :sender, class_name: "User", inverse_of: :sent_messages

  validates :body, presence: true, length: { maximum: 5000 }
  validate  :sender_is_member_or_admin

  scope :chronological, -> { order(:created_at) }
  scope :unread, -> { where(read_at: nil) }

  def from_admin?
    sender.admin?
  end

  def from_member?
    sender_id == member_id
  end

  def read?
    read_at.present?
  end

  private

  # Enforce that only the member themselves or an admin can post in a thread.
  def sender_is_member_or_admin
    return if sender.blank? || member.blank?
    return if sender_id == member_id || sender.admin?

    errors.add(:sender, "must be the member or an admin")
  end
end
