# A lightweight in-app notification shown in the bell menu / notifications page.
class Notification < ApplicationRecord
  belongs_to :user

  validates :kind, :title, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }

  # Create a notification for a user (no-op if user is nil). Returns the record.
  def self.notify(user, kind:, title:, body: nil, url: nil, icon: nil)
    return if user.nil?

    user.notifications.create(kind: kind, title: title, body: body, url: url, icon: icon)
  end

  def read?
    read_at.present?
  end

  def icon_name
    icon.presence || "fa-bell"
  end
end
