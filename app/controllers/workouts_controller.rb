class WorkoutsController < ChartController
  def index
    @category  = params[:category].presence
    @workouts  = Workout.by_category(@category).order(:category, :title)
    @categories = Workout::CATEGORIES
  end

  def show
    @workout = Workout.find(params[:id])
    @related = Workout.where(category: @workout.category).where.not(id: @workout.id).limit(3)
  end
end
