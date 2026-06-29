class SessionsController < ApplicationController
  skip_before_action :require_login, only: [ :new, :create ]

  # Throttle credential stuffing / brute force (disabled in the test env).
  unless Rails.env.test?
    rate_limit to: 10, within: 3.minutes, only: :create,
               with: -> { redirect_to login_path, alert: "Too many sign-in attempts. Please wait a few minutes and try again." }
  end

  def new
  end

  def create
    identifier = params[:username].to_s.downcase.strip
    user = User.find_by("lower(username) = ?", identifier) ||
           User.find_by("lower(email) = ?", identifier)

    if user&.authenticate(params[:password])
      reset_session # prevent session fixation
      log_in(user)
      audit!(:login, subject: user)
      flash[:success] = "Welcome back, #{user.first_name}!"
      redirect_to after_auth_path(user)
    else
      # Record the failed attempt (with the tried identifier, never the password)
      # so brute-force patterns are visible in the audit trail.
      AuditLog.record!(action: :login_failed, subject: user, request: request,
                       metadata: { identifier: identifier })
      flash.now[:danger] = "Invalid username or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    audit!(:logout) if logged_in?
    reset_session
    @current_user = nil
    flash[:success] = "You have been signed out."
    redirect_to root_path
  end
end
