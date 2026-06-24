class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  before_action :require_login

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    flash[:danger] = "Please log in to open your chart."
    redirect_to login_path
  end

  # Where to send a user right after authentication.
  def after_auth_path(user)
    return onboarding_path if user.needs_onboarding?

    user.staff? ? admin_root_path : dashboard_path
  end

  # Gate the app until the user has accepted the current legal documents.
  def require_legal_acceptance
    return if current_user&.accepted_current_legal?

    redirect_to onboarding_path
  end

  def require_staff
    return if current_user&.staff?

    flash[:danger] = "That area is for the care team only."
    redirect_to(current_user ? dashboard_path : login_path)
  end

  def require_owner
    return if current_user&.owner?

    flash[:danger] = "Only the owner can manage that."
    redirect_to admin_root_path
  end

  def log_in(user)
    session[:user_id] = user.id
    @current_user = user
  end
end
