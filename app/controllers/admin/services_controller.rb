module Admin
  class ServicesController < BaseController
    before_action :set_service, only: [ :edit, :update, :destroy ]

    def index
      @services = Service.ordered
      @booking_counts = Appointment.group(:service_id).count
    end

    def new
      @service = Service.new(active: true, duration_min: 60, color: "#4a7c59", icon: "fa-calendar-check",
                             position: (Service.maximum(:position).to_i + 1))
    end

    def create
      @service = Service.new(service_params)
      if @service.save
        redirect_to admin_services_path, success: "#{@service.name} added to the catalog."
      else
        flash.now[:danger] = @service.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @service.update(service_params)
        redirect_to admin_services_path, success: "#{@service.name} updated."
      else
        flash.now[:danger] = @service.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @service.appointments.exists?
        @service.update(active: false)
        redirect_to admin_services_path, success: "#{@service.name} has bookings, so it was hidden instead of deleted."
      else
        @service.destroy
        redirect_to admin_services_path, success: "Service removed."
      end
    end

    private

    def set_service
      @service = Service.find_by!(slug: params[:id])
    end

    def service_params
      params.require(:service).permit(:name, :category, :tagline, :description, :duration_min,
                                      :price_cents, :provider_name, :color, :icon, :active, :position)
    end
  end
end
