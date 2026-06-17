class AppointmentsController < ChartController
  before_action :set_appointment, only: [ :show, :cancel, :calendar ]

  def index
    @upcoming = current_user.appointments.upcoming.includes(:service)
    @past     = current_user.appointments.past.includes(:service).limit(25)
  end

  def show
  end

  def new
    @service = Service.active.find_by!(slug: params[:service_id])
    @appointment = current_user.appointments.new(
      service: @service, duration_min: @service.duration_min,
      scheduled_at: next_business_slot, mode: "in_person"
    )
  end

  def create
    @appointment = current_user.appointments.new(appointment_params)
    if @appointment.save
      redirect_to appointment_path(@appointment),
                  success: "Requested! We'll confirm your #{@appointment.service.name} session shortly."
    else
      @service = @appointment.service
      flash.now[:danger] = "Please fix: #{@appointment.errors.full_messages.to_sentence}."
      render :new, status: :unprocessable_entity
    end
  end

  def cancel
    @appointment.update(status: "cancelled", cancelled_at: Time.current)
    redirect_to appointments_path, success: "Appointment cancelled."
  end

  def calendar
    send_data @appointment.to_ics,
              filename: "hwf-appointment-#{@appointment.id}.ics",
              type: "text/calendar; charset=utf-8"
  end

  private

  def set_appointment
    @appointment = current_user.appointments.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(:service_id, :scheduled_at, :mode, :reason)
  end

  def next_business_slot
    (Time.current + 2.days).change(hour: 9, min: 0)
  end
end
