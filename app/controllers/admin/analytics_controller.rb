module Admin
  class AnalyticsController < BaseController
    def index
      @member_count = User.members.count
      @active_count = User.members.where(id: Checkin.where(checkin_date: 14.days.ago..).select(:user_id)).distinct.count
      @appt_total   = Appointment.count
      @appt_completed = Appointment.where(status: "completed").count

      @appts_by_service = Appointment.joins(:service).group("services.name").count
                                     .sort_by { |_, v| -v }.to_h
      @appts_by_status  = Appointment.group(:status).count
      @workout_categories = WorkoutLog.joins(:workout).group("workouts.category").count
                                      .sort_by { |_, v| -v }.to_h

      @checkins_weekly = weekly_counts(Checkin.all, :created_at)
      @signups_weekly  = weekly_counts(User.members, :created_at)

      @training_progress = TrainingModule.ordered.map do |t|
        done = t.training_completions.acknowledged.count
        { title: t.title, done: done, pct: @member_count.zero? ? 0 : (done * 100.0 / @member_count).round }
      end

      @wellness_distribution = wellness_distribution
    end

    private

    def weekly_counts(scope, column)
      weeks = (0..7).map { |n| Date.current.beginning_of_week - (7 - n).weeks }
      counts = Hash.new(0)
      scope.where(column => 8.weeks.ago.beginning_of_week..).pluck(column).each do |t|
        counts[t.to_date.beginning_of_week] += 1
      end
      { labels: weeks.map { |w| w.strftime("%-m/%-d") }, values: weeks.map { |w| counts[w] } }
    end

    # Bucket each member's most recent wellness score.
    def wellness_distribution
      buckets = { "Low (<50)" => 0, "Okay (50–74)" => 0, "Good (75+)" => 0 }
      User.members.find_each do |m|
        score = m.latest_checkin&.wellness_score
        next unless score

        key = score >= 75 ? "Good (75+)" : score >= 50 ? "Okay (50–74)" : "Low (<50)"
        buckets[key] += 1
      end
      { labels: buckets.keys, values: buckets.values }
    end
  end
end
