# Records acceptance of the current Terms of Use & Privacy Policy (from the
# blocking modal shown to members and non-owner admins).
class LegalAcceptancesController < ApplicationController
  def create
    if params[:accept_terms] == "1" && params[:accept_privacy] == "1"
      current_user.accept_legal!
      redirect_to after_auth_path(current_user), success: "Thanks — you're all set!"
    else
      redirect_back fallback_location: dashboard_path,
                    danger: "Please accept both the Terms of Use and the Privacy Policy to continue."
    end
  end
end
