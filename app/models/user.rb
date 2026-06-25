class User < ApplicationRecord
  has_secure_password

  # Role tiers: member < admin < owner (the single top admin).
  enum :role, { member: "member", admin: "admin", owner: "owner" }, default: "member"

  has_one  :health_profile, dependent: :destroy
  has_many :checkins,     dependent: :destroy
  has_many :meal_entries, dependent: :destroy
  has_many :workout_logs, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :training_completions, dependent: :destroy
  has_many :notifications, dependent: :destroy

  # Messaging: a "thread" is owned by a member; messages may be authored by
  # the member or by a staff member (sender), and are with a provider.
  has_many :messages, foreign_key: :member_id, dependent: :destroy, inverse_of: :member
  has_many :sent_messages, class_name: "Message", foreign_key: :sender_id, dependent: :destroy, inverse_of: :sender
  has_many :assessments, foreign_key: :member_id, dependent: :destroy, inverse_of: :member

  # Care assignments: which providers (staff) look after this member, and which
  # members a provider looks after.
  has_many :care_assignments_as_member, class_name: "CareAssignment", foreign_key: :member_id,
                                        dependent: :destroy, inverse_of: :member
  has_many :providers, through: :care_assignments_as_member, source: :provider
  has_many :care_assignments_as_provider, class_name: "CareAssignment", foreign_key: :provider_id,
                                          dependent: :destroy, inverse_of: :provider
  has_many :assigned_members, through: :care_assignments_as_provider, source: :member

  # Token used for password-reset links (invalidated when the password changes).
  generates_token_for :password_reset, expires_in: 30.minutes do
    password_digest&.last(10)
  end

  scope :members, -> { where(role: "member") }
  scope :admins,  -> { where(role: "admin") }
  scope :staff,   -> { where(role: %w[admin owner]) }

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

  # --- Roles -----------------------------------------------------------------

  # Admins and the owner can both enter the staff portal.
  def staff?
    admin? || owner?
  end

  def role_label
    { "owner" => "Owner", "admin" => "Admin", "member" => "Member" }[role]
  end

  # --- Onboarding & legal ----------------------------------------------------

  def accepted_current_legal?
    terms_accepted_at.present? && privacy_accepted_at.present? &&
      accepted_terms_version == Legal::TERMS_VERSION &&
      accepted_privacy_version == Legal::PRIVACY_VERSION
  end

  # The owner (top admin) is exempt from the legal-acceptance gate.
  def legal_exempt?
    owner?
  end

  def needs_legal?
    !legal_exempt? && !accepted_current_legal?
  end

  def accept_legal!(at = Time.current)
    update!(
      terms_accepted_at: at, privacy_accepted_at: at,
      accepted_terms_version: Legal::TERMS_VERSION,
      accepted_privacy_version: Legal::PRIVACY_VERSION,
      onboarded_at: onboarded_at || at
    )
  end

  # --- Tutorial --------------------------------------------------------------

  def needs_tutorial?
    member? && tutorial_completed_at.nil? && accepted_current_legal?
  end

  def complete_tutorial!
    update_column(:tutorial_completed_at, Time.current) if tutorial_completed_at.nil?
  end

  def restart_tutorial!
    update_column(:tutorial_completed_at, nil)
  end

  # --- Notifications & care --------------------------------------------------

  def unread_notifications_count
    notifications.unread.count
  end

  # Providers a member can message: their assignments, or all staff as a fallback
  # so a brand-new member is never stuck without a recipient.
  def messageable_providers
    list = providers.staff.order(:first_name).to_a
    list.presence || User.staff.order(:role, :first_name).to_a
  end
end
