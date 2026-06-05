class RoutinesController < ChartController
  def index
    @routines = Routine.order(:level, :title)
  end

  def show
    @routine = Routine.find(params[:id])
    @items   = @routine.routine_items.includes(:workout)
  end
end
