module Admin
  class UsersController < BaseController
    def index
      @q = params[:q].to_s.strip
      scope = User.members.order(created_at: :desc)
      if @q.present?
        like = "%#{@q.downcase}%"
        scope = scope.where("lower(first_name) LIKE ? OR lower(last_name) LIKE ? OR lower(email) LIKE ? OR lower(username) LIKE ?",
                            like, like, like, like)
      end
      @members = scope
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
    end

    private

    def series(records)
      records = records.reject { |r| yield(r).nil? }
      { labels: records.map { |r| r.checkin_date.strftime("%b %-d") }, values: records.map { |r| yield(r) } }
    end

    def bmi_series(member)
      history = member.bmi_history(limit: 30)
      { labels: history.map { |d, _| d.strftime("%b %-d") }, values: history.map { |_, v| v } }
    end
  end
end
