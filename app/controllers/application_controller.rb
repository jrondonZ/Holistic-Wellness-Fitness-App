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

  def log_in(user)
    session[:user_id] = user.id
    @current_user = user
  end
end
