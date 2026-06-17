class TrainingsController < ChartController
  before_action :set_training, only: [ :show, :complete ]

  def index
    @trainings   = TrainingModule.ordered
    @completions = current_user.training_completions.index_by(&:training_module_id)
  end

  def show
    @completion = @training.completion_for(current_user)
  end

  def complete
    signature = params[:signature].to_s.strip

    if params[:acknowledge] != "1" || signature.blank?
      return redirect_to training_path(@training),
                         danger: "Please read the material, check the acknowledgement, and sign with your name."
    end

    score = @training.quiz? ? grade(params[:answers]) : nil
    if score && score < TrainingModule::PASS_THRESHOLD
      return redirect_to training_path(@training),
                         danger: "You scored #{score}%. A score of #{TrainingModule::PASS_THRESHOLD}% is required — review the material and try again."
    end

    completion = current_user.training_completions.find_or_initialize_by(training_module: @training)
    completion.update!(acknowledged: true, signature: signature, score: score, completed_at: Time.current)

    redirect_to trainings_path,
                success: "#{@training.title} completed#{score ? " with a score of #{score}%" : ''}. Thank you!"
  end

  private

  def set_training
    @training = TrainingModule.find_by!(slug: params[:id])
  end

  # Percentage of quiz questions answered correctly.
  def grade(answers)
    answers = answers.respond_to?(:to_unsafe_h) ? answers.to_unsafe_h : Hash(answers)
    answers = answers.transform_keys(&:to_s)
    questions = @training.questions
    return 0 if questions.empty?

    correct = questions.each_with_index.count do |q, i|
      answers[i.to_s].to_s == q["answer"].to_s
    end
    (correct * 100.0 / questions.size).round
  end
end
