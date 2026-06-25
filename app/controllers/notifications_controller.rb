class NotificationsController < ApplicationController
  def index
    @notifications = current_user.notifications.recent.limit(60)
  end

  def read
    notification = current_user.notifications.find(params[:id])
    notification.update(read_at: Time.current) unless notification.read?
    redirect_to(safe_url(notification.url) || notifications_path)
  end

  def read_all
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_back fallback_location: notifications_path, notice: "All caught up."
  end

  private

  # Only allow same-origin relative paths to prevent open-redirects.
  def safe_url(url)
    url if url.present? && url.start_with?("/") && !url.start_with?("//")
  end
end
