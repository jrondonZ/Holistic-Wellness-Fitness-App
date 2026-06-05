class SessionsController < ApplicationController
  skip_before_action :require_login, only: [ :new, :create ]

  def new
  end

  def create
    user = User.find_by("lower(username) = ?", params[:username].to_s.downcase.strip) ||
           User.find_by("lower(email) = ?", params[:username].to_s.downcase.strip)

    if user&.authenticate(params[:password])
      log_in(user)
      flash[:success] = "Welcome back, #{user.first_name}!"
      redirect_to dashboard_path
    else
      flash.now[:danger] = "Invalid username or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    @current_user = nil
    flash[:success] = "You have been signed out."
    redirect_to root_path
  end
end
