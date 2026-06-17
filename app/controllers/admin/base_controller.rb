module Admin
  # Base controller for the staff/admin portal. Requires an admin session and
  # renders inside the admin layout.
  class BaseController < ApplicationController
    layout "admin"
    before_action :require_admin

    private

    def require_admin
      return if current_user&.admin?

      flash[:danger] = "That area is for the care team only."
      redirect_to(current_user ? dashboard_path : login_path)
    end

    # Shared unread-thread count for the admin nav badge.
    def unread_thread_count
      @unread_thread_count ||=
        Message.unread.joins(:sender).where.not(users: { role: "admin" }).distinct.count(:member_id)
    end
    helper_method :unread_thread_count
  end
end
