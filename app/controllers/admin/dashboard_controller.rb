module Admin
  class DashboardController < BaseController
    def index
      @member_count   = User.members.count
      @active_count   = User.members.where(id: Checkin.where(checkin_date: 14.days.ago..).select(:user_id)).distinct.count
      @pending_appts  = Appointment.where(status: "requested").count
      @upcoming_appts = Appointment.upcoming.count
      @open_assessments = Assessment.open.count
      @unread_threads = unread_thread_count

      @recent_appointments = Appointment.includes(:user, :service).order(created_at: :desc).limit(6)
      @new_members         = User.members.order(created_at: :desc).limit(5)

      @signup_series  = daily_counts(User.members, :created_at)
      @checkin_series = daily_counts(Checkin.all, :created_at)

      # Members whose charts currently raise a concern-level flag.
      @attention = members_needing_attention
    end

    private

    # Count rows per day for the last 14 days → { labels:, values: }.
    def daily_counts(scope, column)
      days = (0..13).map { |n| Date.current - (13 - n) }
      grouped = scope.where(column => 14.days.ago.beginning_of_day..)
                     .pluck(column).group_by(&:to_date).transform_values(&:size)
      { labels: days.map { |d| d.strftime("%-m/%-d") }, values: days.map { |d| grouped[d].to_i } }
    end

    def members_needing_attention
      active_ids = Checkin.where(checkin_date: 21.days.ago..).distinct.pluck(:user_id)
      User.members.where(id: active_ids).limit(25).filter_map do |member|
        flags = HealthInsights.for(member)
        concern = flags.select { |f| %w[concern urgent watch].include?(f.level) }
        { member: member, flags: concern } if concern.any?
      end.sort_by { |h| h[:flags].any? { |f| %w[concern urgent].include?(f.level) } ? 0 : 1 }.first(6)
    end
  end
end
