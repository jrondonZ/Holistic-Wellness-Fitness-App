class HealthProfilesController < ChartController
  before_action :set_profile

  def show
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to health_profile_path, success: "Your chart details were updated."
    else
      flash.now[:danger] = "Please fix the errors below."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = current_user.ensure_health_profile
  end

  def profile_params
    params.require(:health_profile).permit(
      :date_of_birth, :sex, :height_in, :starting_weight, :goal_weight,
      :activity_level, :dietary_preference, :blood_type, :primary_goal,
      :coach_name, :emergency_contact, :allergies, :conditions
    )
  end
end
