module Admin
  # Base controller for the staff/admin portal. Requires a staff session
  # (admin or owner) and renders inside the admin layout.
  class BaseController < ApplicationController
    layout "admin"
    before_action :require_staff
    before_action :require_legal_acceptance

    private

    # Shared unread-thread count for the admin nav badge (member-authored, unread).
    def unread_thread_count
      @unread_thread_count ||=
        Message.unread.joins(:sender).where(users: { role: "member" }).distinct.count(:member_id)
    end
    helper_method :unread_thread_count
  end
end
