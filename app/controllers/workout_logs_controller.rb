class WorkoutLogsController < ChartController
  before_action :set_workout_log, only: [ :edit, :update, :destroy ]

  def index
    @workout_logs = current_user.workout_logs.recent
    @week_minutes = current_user.workout_logs.this_week.sum(:duration_min)
    @week_sessions = current_user.workout_logs.this_week.count
    @week_burn    = current_user.workout_logs.this_week.sum(:calories_burned)
  end

  def new
    @workout_log = current_user.workout_logs.new(performed_on: Date.current, intensity: "Moderate")
    prefill_from_library
  end

  def create
    @workout_log = current_user.workout_logs.new(workout_log_params)
    if @workout_log.save
      redirect_to workout_logs_path, success: "Workout logged. Keep the momentum going!"
    else
      flash.now[:danger] = "Please fix: #{@workout_log.errors.full_messages.to_sentence}."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @workout_log.update(workout_log_params)
      redirect_to workout_logs_path, success: "Workout updated."
    else
      flash.now[:danger] = "Please fix: #{@workout_log.errors.full_messages.to_sentence}."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workout_log.destroy
    redirect_to workout_logs_path, success: "Workout removed."
  end

  private

  def set_workout_log
    @workout_log = current_user.workout_logs.find(params[:id])
  end

  def workout_log_params
    params.require(:workout_log).permit(
      :performed_on, :activity, :duration_min, :intensity, :calories_burned, :notes, :workout_id
    )
  end

  # Logging straight from a library video pre-fills the form.
  def prefill_from_library
    return if params[:workout_id].blank?

    workout = Workout.find_by(id: params[:workout_id])
    return unless workout

    @workout_log.workout      = workout
    @workout_log.activity     = workout.title
    @workout_log.duration_min = workout.duration_min
    @workout_log.calories_burned = workout.calories_est
  end
end
