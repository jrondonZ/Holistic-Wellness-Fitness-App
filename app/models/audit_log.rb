# An immutable record of who accessed or changed protected health information.
#
# Records are written through AuditLog.record! (typically via the `audit!` helper
# in ApplicationController) and are meant to be append-only — there is no update
# or destroy path in the app. The staff portal can surface these as a member's
# "access history", the way Epic MyChart shows patients who has viewed their chart.
class AuditLog < ApplicationRecord
  belongs_to :actor,   class_name: "User", optional: true
  belongs_to :subject, class_name: "User", optional: true

  # Keep the vocabulary small and stable so the trail is queryable/reportable.
  ACTIONS = %w[view create update destroy login logout login_failed export ai_chat access_denied].freeze

  validates :action, presence: true

  scope :recent,        -> { order(created_at: :desc) }
  scope :for_subject,   ->(user) { where(subject_id: user.is_a?(User) ? user.id : user) }
  scope :by_actor,      ->(user) { where(actor_id: user.is_a?(User) ? user.id : user) }

  # Write an audit entry. Never raises — auditing must not break the request it is
  # observing; a failure to log is itself logged and swallowed.
  #
  #   AuditLog.record!(action: :view, actor: current_user, subject: @member,
  #                    resource: @member.health_profile, request: request)
  def self.record!(action:, actor: nil, subject: nil, resource: nil, request: nil, metadata: {})
    create!(
      action:        action.to_s,
      actor:         actor,
      subject:       subject,
      resource_type: resource&.class&.name,
      resource_id:   (resource.id if resource.respond_to?(:id)),
      ip_address:    request&.remote_ip,
      user_agent:    request&.user_agent.to_s[0, 255],
      metadata:      metadata.presence,
      created_at:    Time.current
    )
  rescue StandardError => e
    Rails.logger.error("[AuditLog] failed to record #{action}: #{e.class}: #{e.message}")
    nil
  end

  def action_label
    action.to_s.humanize
  end
end
