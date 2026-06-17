class User < ApplicationRecord
  has_secure_password

  enum :role, { member: "member", admin: "admin" }, default: "member"

  has_one  :health_profile, dependent: :destroy
  has_many :checkins,     dependent: :destroy
  has_many :meal_entries, dependent: :destroy
  has_many :workout_logs, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :training_completions, dependent: :destroy

  # Messaging: a "thread" is owned by a member; messages may be authored by
  # the member or by an admin (sender).
  has_many :messages, foreign_key: :member_id, dependent: :destroy, inverse_of: :member
  has_many :sent_messages, class_name: "Message", foreign_key: :sender_id, dependent: :destroy, inverse_of: :sender
  has_many :assessments, foreign_key: :member_id, dependent: :destroy, inverse_of: :member

  scope :members, -> { where(role: "member") }
  scope :admins,  -> { where(role: "admin") }

  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :username,   presence: true, uniqueness: { case_sensitive: false }
  validates :email,      presence: true, uniqueness: { case_sensitive: false },
                         format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password,   length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  before_save { self.email = email.to_s.downcase.strip }
  before_save { self.username = username.to_s.strip }
  after_create :ensure_health_profile

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def initials
    [ first_name, last_name ].compact.map { |n| n[0] }.join.upcase
  end

  # MyChart-style member record number.
  def member_id
    format("HWF-%06d", id)
  end

  def ensure_health_profile
    health_profile || create_health_profile!
  end

  # --- Convenience accessors used across the chart ---------------------------

  def latest_checkin
    checkins.order(checkin_date: :desc, id: :desc).first
  end

  # Most recent recorded weight (check-ins first, then the baseline on file).
  def current_weight
    checkins.where.not(weight: nil).order(checkin_date: :desc).limit(1).pick(:weight) ||
      health_profile&.starting_weight
  end

  def calories_for(date = Date.current)
    meal_entries.where(consumed_on: date).sum(:calories)
  end

  def active_minutes_since(date)
    workout_logs.where(performed_on: date..).sum(:duration_min)
  end

  # BMI over time, computed from dated weights and the profile height.
  # Returns an array of [date, bmi] pairs, oldest first.
  def bmi_history(limit: 60)
    profile = health_profile
    return [] unless profile&.height_in.to_f&.positive?

    checkins.where.not(weight: nil).order(checkin_date: :asc).last(limit).map do |c|
      [ c.checkin_date, ((c.weight.to_f / (profile.height_in.to_f**2)) * 703).round(1) ]
    end
  end

  def training_complete?(slug)
    training_completions.joins(:training_module)
                        .where(training_modules: { slug: slug }, acknowledged: true).exists?
  end
end
