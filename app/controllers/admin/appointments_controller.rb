module Admin
  class AppointmentsController < BaseController
    before_action :set_appointment, only: [ :show, :update ]

    def index
      @status = params[:status].presence
      scope = Appointment.includes(:user, :service)
      @appointments =
        case @status
        when "upcoming" then scope.upcoming
        when nil        then scope.order(scheduled_at: :desc)
        else scope.by_status(@status).order(scheduled_at: :desc)
        end
      @counts = Appointment.group(:status).count
      @pending = Appointment.where(status: "requested").count
    end

    def show
    end

    def update
      previous_status = @appointment.status
      if @appointment.update(appointment_params.merge(status_timestamps))
        notify_member(previous_status)
        redirect_to admin_appointment_path(@appointment), success: "Appointment updated."
      else
        flash.now[:danger] = @appointment.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end

    private

    def notify_member(previous_status)
      return if @appointment.status == previous_status

      titles = {
        "confirmed" => "Appointment confirmed",
        "cancelled" => "Appointment cancelled",
        "completed" => "Session marked complete"
      }
      title = titles[@appointment.status]
      return unless title

      Notification.notify(@appointment.user, kind: "appointment", icon: "fa-calendar-check",
                          title: title,
                          body: "#{@appointment.service.name} · #{@appointment.scheduled_at.strftime('%b %-d, %-l:%M %p')}",
                          url: appointment_path(@appointment))
    end

    def set_appointment
      @appointment = Appointment.find(params[:id])
    end

    def appointment_params
      params.require(:appointment).permit(:status, :mode, :scheduled_at, :duration_min,
                                          :location, :meeting_url, :admin_notes)
    end

    def status_timestamps
      case params.dig(:appointment, :status)
      when "confirmed" then { confirmed_at: Time.current }
      when "cancelled" then { cancelled_at: Time.current }
      else {}
      end
    end
  end
end
