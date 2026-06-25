# Forgot-password flow using a short-lived signed token (no DB column needed).
class PasswordResetsController < ApplicationController
  skip_before_action :require_login
  before_action :set_user_by_token, only: [ :edit, :update ]

  def new
  end

  def create
    user = User.find_by("lower(email) = ?", params[:email].to_s.downcase.strip)
    if user
      token = user.generate_token_for(:password_reset)
      PasswordMailer.reset(user, token).deliver_now
      # Dev convenience: the link is logged so it can be used without an SMTP server.
      Rails.logger.info("[password_reset] #{edit_password_reset_url(token)}") unless Rails.env.production?
    end
    # Same response whether or not the email exists (no account enumeration).
    redirect_to login_path, notice: "If an account exists for that email, a reset link is on its way."
  end

  def edit
  end

  def update
    if params[:password].to_s.length < 6
      flash.now[:danger] = "Your password must be at least 6 characters."
      render :edit, status: :unprocessable_entity
    elsif @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      redirect_to login_path, success: "Your password was reset. You can now sign in."
    else
      flash.now[:danger] = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_token_for(:password_reset, params[:token])
    return if @user

    redirect_to new_password_reset_path, danger: "That reset link is invalid or has expired."
  end
end
