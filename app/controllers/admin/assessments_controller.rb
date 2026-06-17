module Admin
  # The "help diagnose" tool — care-team assessments recorded on a member chart.
  class AssessmentsController < BaseController
    before_action :set_member

    def create
      @assessment = @member.assessments.new(assessment_params.merge(author: current_user))
      if @assessment.save
        redirect_to admin_user_path(@member, anchor: "diagnose"), success: "Assessment added to the chart."
      else
        redirect_to admin_user_path(@member, anchor: "diagnose"), danger: @assessment.errors.full_messages.to_sentence
      end
    end

    def update
      @assessment = @member.assessments.find(params[:id])
      if @assessment.update(assessment_params)
        redirect_to admin_user_path(@member, anchor: "diagnose"), success: "Assessment updated."
      else
        redirect_to admin_user_path(@member, anchor: "diagnose"), danger: @assessment.errors.full_messages.to_sentence
      end
    end

    def destroy
      @member.assessments.find(params[:id]).destroy
      redirect_to admin_user_path(@member, anchor: "diagnose"), success: "Assessment removed."
    end

    private

    def set_member
      @member = User.members.find(params[:user_id])
    end

    def assessment_params
      params.require(:assessment).permit(:title, :category, :severity, :status, :summary, :recommendations)
    end
  end
end
