# First-run walkthrough that ends with accepting the Terms & Privacy Policy.
class OnboardingController < ApplicationController
  layout "minimal"

  def show
    return redirect_to after_auth_path(current_user) if current_user.accepted_current_legal?

    @user = current_user
  end

  def update
    if params[:accept_terms] == "1" && params[:accept_privacy] == "1"
      current_user.accept_legal!
      redirect_to after_auth_path(current_user), success: "You're all set — welcome to Holistic Chart!"
    else
      redirect_to onboarding_path, danger: "Please accept the Terms of Use and the Privacy Policy to continue."
    end
  end
end
