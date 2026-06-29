module Admin
  class UsersController < BaseController
    before_action :require_owner, only: [ :new, :create, :edit, :update, :destroy ]
    before_action :set_user, only: [ :edit, :update, :destroy ]

    def index
      @q = params[:q].to_s.strip
      scope = current_user.owner? ? User.all : User.members
      scope = scope.order(Arel.sql("CASE role WHEN 'owner' THEN 0 WHEN 'admin' THEN 1 ELSE 2 END"))
                   .order(created_at: :desc)
      if @q.present?
        like = "%#{@q.downcase}%"
        scope = scope.where(
          "lower(first_name) LIKE :q OR lower(last_name) LIKE :q OR lower(email) LIKE :q OR lower(username) LIKE :q",
          q: like
        )
      end
      @users = scope
      @checkin_counts = Checkin.group(:user_id).count
      @last_checkin   = Checkin.group(:user_id).maximum(:checkin_date)
    end

    def show
      @member  = User.members.find(params[:id])
      @profile = @member.ensure_health_profile
      @flags   = HealthInsights.for(@member)
      @recent_checkins = @member.checkins.order(checkin_date: :desc).limit(7)
      @appointments    = @member.appointments.includes(:service).order(scheduled_at: :desc).limit(8)
      @assessments     = @member.assessments.recent.includes(:author)
      @assessment      = Assessment.new
      @weight_series   = series(@member.checkins.where.not(weight: nil).order(:checkin_date).last(30)) { |c| c.weight.to_f }
      @bmi_series      = bmi_series(@member)
      @unread          = @member.messages.unread.where.not(sender_id: @member.id).count
      @week_minutes    = @member.workout_logs.where(performed_on: Date.current.beginning_of_week..).sum(:duration_min)
      @assignments     = @member.care_assignments_as_member.includes(:provider).primary_first
      @available_providers = User.staff.where.not(id: @member.providers.select(:id)).order(:first_name)

      # PHI access trail: a staff member opened a member's health record.
      audit!(:view, subject: @member, resource: @member.health_profile, metadata: { area: "admin_member_chart" })
    end

    def new
      @user = User.new(role: "member")
    end

    def create
      @user = User.new(user_params)
      @user.role = safe_role
      if @user.save
        redirect_to admin_users_path, success: "#{@user.full_name} was created."
      else
        flash.now[:danger] = @user.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @user.assign_attributes(user_params)
      # Role is set explicitly (never mass-assigned) and the owner's role is immutable.
      @user.role = safe_role if !@user.owner? && params.dig(:user, :role).present?
      if @user.save
        redirect_to admin_users_path, success: "#{@user.full_name} was updated."
      else
        flash.now[:danger] = @user.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, danger: "You can't delete your own account here."
      elsif @user.owner?
        redirect_to admin_users_path, danger: "The owner account can't be deleted."
      else
        @user.destroy
        redirect_to admin_users_path, success: "#{@user.full_name} was deleted."
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def series(records)
      records = records.reject { |r| yield(r).nil? }
      { labels: records.map { |r| r.checkin_date.strftime("%b %-d") }, values: records.map { |r| yield(r) } }
    end

    def bmi_series(member)
      history = member.bmi_history(limit: 30)
      { labels: history.map { |d, _| d.strftime("%b %-d") }, values: history.map { |_, v| v } }
    end

    # Role is intentionally NOT permitted here — it is set explicitly via #safe_role.
    def user_params
      permitted = [ :first_name, :last_name, :username, :email, :title, :phone ]
      permitted += [ :password, :password_confirmation ] if params.dig(:user, :password).present?
      params.require(:user).permit(*permitted)
    end

    # Whitelist to member/admin only — the single "owner" can never be created here.
    def safe_role
      role = params.dig(:user, :role)
      %w[member admin].include?(role) ? role : "member"
    end
  end
end
