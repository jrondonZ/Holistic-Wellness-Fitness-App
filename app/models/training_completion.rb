# Records a member's completion (and acknowledgement) of a training module.
class TrainingCompletion < ApplicationRecord
  belongs_to :user
  belongs_to :training_module

  validates :user_id, uniqueness: { scope: :training_module_id }

  scope :acknowledged, -> { where(acknowledged: true) }

  def passed?
    acknowledged? && (score.nil? || score >= TrainingModule::PASS_THRESHOLD)
  end
end
