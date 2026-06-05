class CheckinsController < ChartController
  before_action :set_checkin, only: [ :show, :edit, :update, :destroy ]

  def index
    @checkins = current_user.checkins.recent
    trend = current_user.checkins.chronological.where(checkin_date: 30.days.ago..).to_a
    @weight_series   = chart_series(trend.select { |c| c.weight.present? }) { |c| c.weight.to_f }
    @wellness_series = chart_series(trend) { |c| c.wellness_score }
  end

  def show
  end

  def new
    @checkin = current_user.checkins.new(
      checkin_date: Date.current,
      mood: 3, energy: 3, stress: 2
    )
  end

  def create
    @checkin = current_user.checkins.new(checkin_params)
    if @checkin.save
      redirect_to checkins_path, success: "Check-in logged. Nice work staying consistent!"
    else
      flash.now[:danger] = error_summary(@checkin)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @checkin.update(checkin_params)
      redirect_to checkins_path, success: "Check-in updated."
    else
      flash.now[:danger] = error_summary(@checkin)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @checkin.destroy
    redirect_to checkins_path, success: "Check-in removed."
  end

  private

  def set_checkin
    @checkin = current_user.checkins.find(params[:id])
  end

  def checkin_params
    params.require(:checkin).permit(
      :checkin_date, :mood, :energy, :stress, :sleep_hours, :water_oz,
      :weight, :resting_hr, :systolic, :diastolic, :notes
    )
  end

  def chart_series(records)
    records = records.reject { |r| yield(r).nil? }
    { labels: records.map { |r| r.checkin_date.strftime("%b %-d") },
      values: records.map { |r| yield(r) } }
  end

  def error_summary(record)
    "Please fix: #{record.errors.full_messages.to_sentence}."
  end
end
