class User < ApplicationRecord
  has_secure_password

  has_one  :health_profile, dependent: :destroy
  has_many :checkins,     dependent: :destroy
  has_many :meal_entries, dependent: :destroy
  has_many :workout_logs, dependent: :destroy

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
end
