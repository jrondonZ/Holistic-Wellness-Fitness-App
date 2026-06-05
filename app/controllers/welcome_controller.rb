class WelcomeController < ApplicationController
  skip_before_action :require_login

  def index
    redirect_to dashboard_path if logged_in?
  end
end
