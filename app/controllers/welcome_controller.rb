class WelcomeController < ApplicationController
  skip_before_action :require_login

  def index
    redirect_to after_auth_path(current_user) if logged_in?
  end
end
