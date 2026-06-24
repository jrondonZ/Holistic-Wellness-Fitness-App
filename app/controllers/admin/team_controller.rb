module Admin
  # Owner-only management of the care team (admins). The single owner cannot be
  # demoted, removed, or duplicated here — there is exactly one top admin.
  class TeamController < BaseController
    before_action :require_owner

    def index
      @staff   = User.staff.order(:role, :first_name)
      @members = User.members.order(:first_name, :last_name)
      @user    = User.new
    end

    # Create a brand-new admin account.
    def create
      @user = User.new(staff_params.merge(role: "admin"))
      if @user.save
        redirect_to admin_team_path, success: "#{@user.full_name} was added as an admin."
      else
        redirect_to admin_team_path, danger: "Could not add admin: #{@user.errors.full_messages.to_sentence}."
      end
    end

    # Promote a member to admin or demote an admin to member.
    def update
      user = User.find(params[:id])
      return guard_owner(user) if user.owner?

      new_role = params[:role].to_s
      unless %w[member admin].include?(new_role)
        return redirect_to admin_team_path, danger: "Invalid role."
      end

      user.update!(role: new_role)
      redirect_to admin_team_path, success: "#{user.full_name} is now #{user.role_label}."
    end

    # Remove admin rights (demote back to member). Never deletes the account.
    def destroy
      user = User.find(params[:id])
      return guard_owner(user) if user.owner?

      user.update!(role: "member")
      redirect_to admin_team_path, success: "#{user.full_name} was removed from the care team."
    end

    private

    def guard_owner(_user)
      redirect_to admin_team_path, danger: "The owner is the top admin and can't be changed here."
    end

    def staff_params
      params.require(:user).permit(:first_name, :last_name, :username, :email,
                                   :title, :phone, :password, :password_confirmation)
    end
  end
end
