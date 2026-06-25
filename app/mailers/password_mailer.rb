class PasswordMailer < ApplicationMailer
  def reset(user, token)
    @user = user
    @reset_url = edit_password_reset_url(token)
    mail(to: user.email, subject: "Reset your Holistic Chart password")
  end
end
