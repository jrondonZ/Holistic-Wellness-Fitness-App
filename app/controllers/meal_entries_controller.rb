class MealEntriesController < ChartController
  before_action :set_meal_entry, only: [ :edit, :update, :destroy ]

  def index
    @date  = parse_date(params[:date]) || Date.current
    @meals = current_user.meal_entries.for_date(@date)
                         .sort_by { |m| MealEntry.meal_order.fetch(m.meal_type, 99) }
    @totals = totals(@meals)
    @target = current_user.ensure_health_profile.target_calories
    @recent_days = current_user.meal_entries
                               .where(consumed_on: (@date - 6)..@date)
                               .group(:consumed_on).sum(:calories)
  end

  def new
    @meal_entry = current_user.meal_entries.new(
      consumed_on: parse_date(params[:date]) || Date.current,
      meal_type: suggested_meal_type
    )
  end

  def create
    @meal_entry = current_user.meal_entries.new(meal_entry_params)
    if @meal_entry.save
      redirect_to meal_entries_path(date: @meal_entry.consumed_on), success: "Meal logged."
    else
      flash.now[:danger] = "Please fix: #{@meal_entry.errors.full_messages.to_sentence}."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @meal_entry.update(meal_entry_params)
      redirect_to meal_entries_path(date: @meal_entry.consumed_on), success: "Meal updated."
    else
      flash.now[:danger] = "Please fix: #{@meal_entry.errors.full_messages.to_sentence}."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    date = @meal_entry.consumed_on
    @meal_entry.destroy
    redirect_to meal_entries_path(date: date), success: "Meal removed."
  end

  private

  def set_meal_entry
    @meal_entry = current_user.meal_entries.find(params[:id])
  end

  def meal_entry_params
    params.require(:meal_entry).permit(
      :consumed_on, :meal_type, :name, :description,
      :calories, :protein_g, :carbs_g, :fat_g
    )
  end

  def totals(meals)
    { calories: meals.sum { |m| m.calories.to_i },
      protein:  meals.sum { |m| m.protein_g.to_i },
      carbs:    meals.sum { |m| m.carbs_g.to_i },
      fat:      meals.sum { |m| m.fat_g.to_i } }
  end

  def suggested_meal_type
    case Time.current.hour
    when 4..10  then "Breakfast"
    when 11..15 then "Lunch"
    when 16..21 then "Dinner"
    else "Snack"
    end
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
