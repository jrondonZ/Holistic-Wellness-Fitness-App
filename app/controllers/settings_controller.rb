# Account settings: edit own profile and change password.
class SettingsController < ApplicationController
  def show
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to settings_path, success: "Your profile was updated."
    else
      flash.now[:danger] = @user.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  def update_password
    @user = current_user
    if !current_user.authenticate(params[:current_password].to_s)
      redirect_to settings_path, danger: "Your current password is incorrect."
    elsif params[:password].to_s.length < User::MIN_PASSWORD_LENGTH
      redirect_to settings_path, danger: "Your new password must be at least #{User::MIN_PASSWORD_LENGTH} characters."
    elsif params[:password] != params[:password_confirmation]
      redirect_to settings_path, danger: "New password and confirmation don't match."
    elsif current_user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      user = current_user
      reset_session # rotate the session after a credential change
      log_in(user)  # keep the user signed in
      redirect_to settings_path, success: "Your password was changed."
    else
      redirect_to settings_path, danger: current_user.errors.full_messages.to_sentence
    end
  end

  private

  # Role is intentionally NOT permitted here.
  def profile_params
    params.require(:user).permit(:first_name, :last_name, :email, :username, :phone)
  end
end
