# A compliance/education training (e.g. HIPAA privacy training) members complete.
class TrainingModule < ApplicationRecord
  serialize :quiz, coder: JSON

  has_many :training_completions, dependent: :destroy
  has_many :users, through: :training_completions

  validates :slug, presence: true, uniqueness: true
  validates :title, presence: true

  scope :ordered,  -> { order(:position, :title) }
  scope :required, -> { where(required: true) }

  PASS_THRESHOLD = 70 # percent

  def to_param
    slug
  end

  # Body split into rendered sections; lines starting with "## " become headings.
  def sections
    body.to_s.split(/\n{2,}/).map(&:strip).reject(&:blank?)
  end

  def questions
    Array(quiz)
  end

  def quiz?
    questions.any?
  end

  def completion_for(user)
    training_completions.find_by(user: user)
  end
end
