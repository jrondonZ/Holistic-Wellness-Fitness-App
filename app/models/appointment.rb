# A member's booking for a service at a scheduled time.
class Appointment < ApplicationRecord
  belongs_to :user
  belongs_to :service

  STATUSES = %w[requested confirmed completed cancelled].freeze
  MODES    = %w[in_person virtual].freeze

  validates :scheduled_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :mode, inclusion: { in: MODES }
  validate  :not_in_the_past, on: :create

  before_validation :inherit_service_duration, on: :create

  scope :upcoming,  -> { where(scheduled_at: Time.current..).where.not(status: "cancelled").order(:scheduled_at) }
  scope :past,      -> { where(scheduled_at: ...Time.current).or(where(status: %w[completed cancelled])).order(scheduled_at: :desc) }
  scope :active,    -> { where.not(status: "cancelled") }
  scope :by_status, ->(s) { where(status: s) if s.present? }
  scope :chronological, -> { order(:scheduled_at) }

  def ends_at
    scheduled_at + (duration_min || service&.duration_min || 60).minutes
  end

  def virtual?
    mode == "virtual"
  end

  def cancelled?
    status == "cancelled"
  end

  def upcoming?
    scheduled_at.future? && !cancelled?
  end

  def status_tone
    case status
    when "confirmed" then "good"
    when "requested" then "ok"
    when "completed" then "muted"
    when "cancelled" then "low"
    else "muted"
    end
  end

  def mode_label
    virtual? ? "Virtual" : "In person"
  end

  # A minimal iCalendar payload so members can add the session to any calendar.
  def to_ics
    stamp = ->(t) { t.utc.strftime("%Y%m%dT%H%M%SZ") }
    summary = "#{service&.name} · Holistic Wellness Fitness"
    location = virtual? ? (meeting_url.presence || "Virtual session") : (location_or_default)
    <<~ICS
      BEGIN:VCALENDAR
      VERSION:2.0
      PRODID:-//Holistic Wellness Fitness//Holistic Chart//EN
      BEGIN:VEVENT
      UID:appointment-#{id}@holisticchart
      DTSTAMP:#{stamp.call(Time.current)}
      DTSTART:#{stamp.call(scheduled_at)}
      DTEND:#{stamp.call(ends_at)}
      SUMMARY:#{summary}
      DESCRIPTION:#{reason.to_s.gsub("\n", ' ')}
      LOCATION:#{location}
      END:VEVENT
      END:VCALENDAR
    ICS
  end

  private

  def location_or_default
    location.presence || "177 State Street, Meriden, CT 06450"
  end

  def inherit_service_duration
    self.duration_min ||= service&.duration_min
  end

  def not_in_the_past
    return if scheduled_at.blank?

    errors.add(:scheduled_at, "can't be in the past") if scheduled_at < Time.current
  end
end
