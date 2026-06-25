# Tracks the first-run interactive tutorial.
class TutorialsController < ApplicationController
  # Marked complete via fetch() from the tour controller.
  def complete
    current_user.complete_tutorial!
    head :ok
  end

  # Replay the walkthrough.
  def restart
    current_user.restart_tutorial!
    redirect_to dashboard_path, notice: "The tutorial will play again."
  end
end
