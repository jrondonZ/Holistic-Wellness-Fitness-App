module Admin
  # Owner-only: assign / unassign providers (staff) to a member.
  class CareAssignmentsController < BaseController
    before_action :require_owner
    before_action :set_member

    def create
      provider = User.staff.find(params[:provider_id])
      assignment = @member.care_assignments_as_member.new(provider: provider, specialty: provider.title)
      if assignment.save
        Notification.notify(@member, kind: "care", icon: "fa-user-doctor",
                            title: "#{provider.full_name} joined your care team",
                            body: provider.title.presence, url: message_thread_path(provider))
        Notification.notify(provider, kind: "care", icon: "fa-user-plus",
                            title: "You were assigned to #{@member.full_name}",
                            url: admin_user_path(@member))
        redirect_to admin_user_path(@member, anchor: "care"), success: "#{provider.full_name} assigned."
      else
        redirect_to admin_user_path(@member, anchor: "care"), danger: assignment.errors.full_messages.to_sentence
      end
    end

    def destroy
      @member.care_assignments_as_member.find(params[:id]).destroy
      redirect_to admin_user_path(@member, anchor: "care"), success: "Provider unassigned."
    end

    private

    def set_member
      @member = User.members.find(params[:user_id])
    end
  end
end
