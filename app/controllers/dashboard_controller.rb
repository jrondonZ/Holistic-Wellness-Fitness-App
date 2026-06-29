class DashboardController < ChartController
  def index
    @profile = current_user.ensure_health_profile
    @today   = Date.current

    # --- Wellness -------------------------------------------------------------
    @latest_checkin   = current_user.latest_checkin
    @recent_checkins  = current_user.checkins.recent.limit(7)
    @checkin_streak   = checkin_streak
    trend_checkins    = current_user.checkins.chronological.where(checkin_date: 30.days.ago..).to_a

    # --- Diet -----------------------------------------------------------------
    @today_meals      = current_user.meal_entries.for_date(@today).to_a
    @nutrition        = summarize(@today_meals)
    @calorie_target   = @profile.target_calories

    # --- Fitness --------------------------------------------------------------
    @recent_workouts  = current_user.workout_logs.recent.limit(5)
    @week_minutes     = current_user.workout_logs.this_week.sum(:duration_min)
    @week_sessions    = current_user.workout_logs.this_week.count
    @week_burn        = current_user.workout_logs.this_week.sum(:calories_burned)

    # --- Care plan / education ------------------------------------------------
    @recommended_workouts = recommended_workouts
    @recommended_articles = Article.newest.limit(3)

    # --- Scheduling & training shortcuts -------------------------------------
    @next_appointment = current_user.appointments.upcoming.includes(:service).first
    @required_training = TrainingModule.required.ordered
    @training_done = current_user.training_completions.acknowledged.count

    # --- Trend series for the chart cards ------------------------------------
    @weight_series   = series(trend_checkins.select { |c| c.weight.present? }) { |c| c.weight.to_f }
    @wellness_series = series(trend_checkins) { |c| c.wellness_score }
    @bmi_series      = bmi_series
    @nutrition_week  = nutrition_week_series

    # PHI access trail: the member opened their own chart summary.
    audit!(:view, resource: @profile, metadata: { area: "chart_summary" })
  end

  private

  def summarize(meals)
    {
      calories: meals.sum { |m| m.calories.to_i },
      protein:  meals.sum { |m| m.protein_g.to_i },
      carbs:    meals.sum { |m| m.carbs_g.to_i },
      fat:      meals.sum { |m| m.fat_g.to_i }
    }
  end

  # BMI over time from the member's dated weights and profile height.
  def bmi_series
    history = current_user.bmi_history(limit: 30)
    { labels: history.map { |d, _| d.strftime("%b %-d") }, values: history.map { |_, v| v } }
  end

  # Build { labels: [...], values: [...] } skipping nil measurements.
  def series(records)
    records = records.reject { |r| yield(r).nil? }
    {
      labels: records.map { |r| r.checkin_date.strftime("%b %-d") },
      values: records.map { |r| yield(r) }
    }
  end

  # Calories consumed per day for the last 7 days.
  def nutrition_week_series
    days = (0..6).map { |n| @today - (6 - n) }
    totals = current_user.meal_entries
                         .where(consumed_on: days.first..days.last)
                         .group(:consumed_on).sum(:calories)
    {
      labels: days.map { |d| d.strftime("%a") },
      values: days.map { |d| totals[d].to_i }
    }
  end

  # Count consecutive days (ending today or yesterday) with a check-in.
  def checkin_streak
    dates = current_user.checkins.order(checkin_date: :desc).limit(60).pluck(:checkin_date).uniq
    return 0 if dates.empty?

    cursor = dates.first
    return 0 if cursor < Date.current - 1

    streak = 0
    dates.each do |d|
      break unless d == cursor

      streak += 1
      cursor -= 1
    end
    streak
  end

  def recommended_workouts
    goal = @profile.primary_goal
    preferred =
      case goal
      when "Build strength" then %w[Strength HIIT]
      when "Weight loss"    then %w[HIIT Cardio]
      when "Stress & balance" then %w[Yoga Mobility Recovery]
      when "Increase energy" then %w[Cardio Pilates]
      else Workout::CATEGORIES
      end
    Workout.where(category: preferred).order("RANDOM()").limit(3).presence ||
      Workout.order("RANDOM()").limit(3)
  end
end
