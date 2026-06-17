# Rule-based "diagnostic helper" that surfaces flags from a member's chart data.
# Not medical advice — it highlights patterns for the care team to review.
class HealthInsights
  Flag = Struct.new(:level, :title, :detail, :icon, keyword_init: true)

  def self.for(user)
    new(user).flags
  end

  def initialize(user)
    @user = user
    @recent = user.checkins.order(checkin_date: :desc).limit(7).to_a
    @profile = user.health_profile
  end

  def flags
    out = [ blood_pressure, wellness, stress, sleep, activity, weight_trend, adherence ].compact
    out.presence || [ Flag.new(level: "good", title: "No flags", icon: "fa-circle-check",
                               detail: "Recent metrics are within healthy ranges.") ]
  end

  private

  attr_reader :recent, :profile, :user

  def latest = recent.first

  def blood_pressure
    c = recent.find { |x| x.systolic && x.diastolic }
    return unless c

    if c.systolic >= 140 || c.diastolic >= 90
      Flag.new(level: "concern", icon: "fa-heart-pulse", title: "Elevated blood pressure",
               detail: "Last reading #{c.blood_pressure} (#{c.bp_category}) on #{c.checkin_date.strftime('%b %-d')}.")
    elsif c.systolic >= 130 || c.diastolic >= 80
      Flag.new(level: "watch", icon: "fa-heart-pulse", title: "Borderline blood pressure",
               detail: "Last reading #{c.blood_pressure} (#{c.bp_category}). Worth monitoring.")
    end
  end

  def wellness
    scores = recent.map(&:wellness_score).compact
    return if scores.empty?

    avg = scores.sum / scores.size
    if avg < 50
      Flag.new(level: "concern", icon: "fa-face-frown", title: "Low wellbeing trend",
               detail: "7-day average wellness score is #{avg}/100.")
    elsif avg < 65
      Flag.new(level: "watch", icon: "fa-face-meh", title: "Dipping wellbeing",
               detail: "7-day average wellness score is #{avg}/100.")
    end
  end

  def stress
    values = recent.map(&:stress).compact
    return if values.empty?

    avg = values.sum.to_f / values.size
    return unless avg >= 3.5

    Flag.new(level: "watch", icon: "fa-bolt", title: "Elevated stress",
             detail: "Average stress is #{avg.round(1)}/5 over recent check-ins.")
  end

  def sleep
    hours = recent.map(&:sleep_hours).compact
    return if hours.empty?

    avg = hours.sum / hours.size
    return unless avg < 6

    Flag.new(level: "watch", icon: "fa-moon", title: "Short sleep",
             detail: "Averaging #{avg.round(1)} hrs/night recently.")
  end

  def activity
    minutes = user.workout_logs.where(performed_on: Date.current.beginning_of_week..).sum(:duration_min)
    return if minutes >= 90

    Flag.new(level: "watch", icon: "fa-dumbbell", title: "Low activity this week",
             detail: "#{minutes} active minutes logged so far this week.")
  end

  def weight_trend
    weighed = user.checkins.where.not(weight: nil).order(checkin_date: :asc).last(10)
    return if weighed.size < 3

    change = (weighed.last.weight - weighed.first.weight).to_f.round(1)
    goal = profile&.primary_goal
    if goal == "Weight loss" && change > 1
      Flag.new(level: "watch", icon: "fa-weight-scale", title: "Weight trending up",
               detail: "+#{change} lb across recent check-ins despite a weight-loss goal.")
    elsif change.abs >= 5
      Flag.new(level: "info", icon: "fa-weight-scale", title: "Notable weight change",
               detail: "#{change.positive? ? '+' : ''}#{change} lb across recent check-ins.")
    end
  end

  def adherence
    last = latest&.checkin_date
    days = last ? (Date.current - last).to_i : nil
    return if days && days <= 5

    Flag.new(level: "watch", icon: "fa-calendar-xmark", title: "No recent check-ins",
             detail: last ? "Last check-in was #{days} days ago." : "No check-ins on file yet.")
  end
end
