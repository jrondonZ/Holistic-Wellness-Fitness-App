module AdminHelper
  ADMIN_NAV = [
    { label: "Overview",     icon: "fa-gauge-high",     path: :admin_root_path },
    { label: "Members",      icon: "fa-users",          path: :admin_users_path },
    { label: "Appointments", icon: "fa-calendar-check", path: :admin_appointments_path },
    { label: "Messages",     icon: "fa-comments",       path: :admin_conversations_path, badge: :threads },
    { label: "Services",     icon: "fa-list-check",     path: :admin_services_path },
    { label: "Analytics",    icon: "fa-chart-line",     path: :admin_analytics_path }
  ].freeze

  def admin_nav_items
    ADMIN_NAV.map { |item| item.merge(href: send(item[:path])) }
  end

  # Tone class for a HealthInsights flag level or assessment severity.
  def flag_tone(level)
    case level.to_s
    when "good" then "good"
    when "watch", "info" then "ok"
    when "concern", "urgent" then "low"
    else "muted"
    end
  end

  def severity_tone(severity)
    case severity.to_s
    when "info" then "muted"
    when "watch" then "ok"
    when "concern", "urgent" then "low"
    else "muted"
    end
  end

  def appt_when(appointment)
    appointment.scheduled_at.strftime("%a, %b %-d · %-l:%M %p")
  end

  def status_pill(status)
    tone = { "requested" => "ok", "confirmed" => "good", "completed" => "muted", "cancelled" => "low" }[status] || "muted"
    tag.span(status.titleize, class: "pill #{tone}")
  end
end
