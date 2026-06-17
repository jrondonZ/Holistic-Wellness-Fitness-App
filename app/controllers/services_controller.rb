class ServicesController < ChartController
  def index
    @category   = params[:category].presence
    @services   = Service.active.in_category(@category).ordered
    @categories = Service::CATEGORIES
    @upcoming   = current_user.appointments.upcoming.includes(:service).limit(4)
  end

  def show
    @service = Service.active.find_by!(slug: params[:id])
  end
end
