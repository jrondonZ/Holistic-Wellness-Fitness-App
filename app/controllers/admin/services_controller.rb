module Admin
  class ServicesController < BaseController
    before_action :set_service, only: [ :edit, :update ]

    def index
      @services = Service.ordered
      @booking_counts = Appointment.group(:service_id).count
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
