class UsersController < ApplicationController
  skip_before_action :require_login, only: [ :new, :create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params) # role is NOT permitted — members can't self-promote
    if @user.save
      reset_session
      log_in(@user)
      flash[:success] = "Welcome to your holistic chart, #{@user.first_name}!"
      redirect_to after_auth_path(@user)
    else
      flash.now[:danger] = "Please fix the errors below."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    user = User.find(params[:id])
    if user == current_user
      user.destroy
      reset_session
      flash[:success] = "Your account and chart have been deleted."
      redirect_to root_path
    else
      flash[:danger] = "You can only delete your own account."
      redirect_to dashboard_path
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :username, :email,
                                 :password, :password_confirmation)
  end
end
