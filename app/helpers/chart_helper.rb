module ChartHelper
  # The left-rail navigation items for the chart.
  CHART_NAV = [
    { label: "Chart Summary", icon: "fa-heart-pulse",   path: :dashboard_path },
    { label: "Wellness",      icon: "fa-spa",            path: :checkins_path },
    { label: "Nutrition",     icon: "fa-bowl-food",      path: :meal_entries_path },
    { label: "Fitness Log",   icon: "fa-dumbbell",       path: :workout_logs_path },
    { label: "Video Library", icon: "fa-circle-play",    path: :workouts_path },
    { label: "Routines",      icon: "fa-calendar-check", path: :routines_path },
    { label: "Education",     icon: "fa-book-open",       path: :articles_path },
    { label: "My Details",    icon: "fa-id-card",         path: :health_profile_path }
  ].freeze

  def chart_nav_items
    CHART_NAV.map { |item| item.merge(href: send(item[:path])) }
  end

  def nav_active?(href)
    current = request.path
    return current == href if href == root_path

    current == href || current.start_with?("#{href}/")
  end

  # Render a 1–5 scale as filled / empty dots.
  def scale_dots(value, max = 5)
    value = value.to_i
    safe_join((1..max).map do |i|
      tag.span(class: "scale-dot #{'is-on' if i <= value}")
    end)
  end

  def metric_value(value, unit: nil, blank: "—")
    return blank if value.blank?

    safe_join([ value.to_s, (tag.span(unit, class: "metric-unit") if unit) ].compact, " ")
  end

  # Colour band for a wellness/score value out of 100.
  def score_tone(score)
    return "muted" if score.blank?

    case score
    when 75.. then "good"
    when 50...75 then "ok"
    else "low"
    end
  end

  def bp_tone(category)
    case category
    when "Normal" then "good"
    when "Elevated" then "ok"
    when "Stage 1", "Stage 2" then "low"
    else "muted"
    end
  end

  # JSON payload consumed by the Stimulus chart controller.
  def trend_payload(series, label:, color: "#4a7c59", type: "line")
    {
      type: type,
      label: label,
      color: color,
      labels: series[:labels],
      values: series[:values]
    }.to_json
  end

  def initials_badge(user, extra_class: "")
    tag.span(user.initials.presence || "·", class: "avatar-badge #{extra_class}")
  end

  # A segmented 1–5 radio control for the subjective wellness scales.
  def scale_field(form, attribute, labels)
    tag.div(class: "scale-input") do
      safe_join((1..5).map do |i|
        form.radio_button(attribute, i) +
          form.label(attribute, value: i) do
            safe_join([ tag.div(i, class: "fw-bold"), tag.div(labels[i], class: "small") ])
          end
      end)
    end
  end
end
