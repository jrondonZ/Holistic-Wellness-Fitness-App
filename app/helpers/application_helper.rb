module ApplicationHelper
  # Map flash keys to Bootstrap alert variants.
  def flash_variant(key)
    case key.to_s
    when "success", "notice" then "success"
    when "danger", "alert", "error" then "danger"
    when "warning" then "warning"
    else "info"
    end
  end

  def flash_icon(key)
    case flash_variant(key)
    when "success" then "fa-circle-check"
    when "danger"  then "fa-circle-exclamation"
    when "warning" then "fa-triangle-exclamation"
    else "fa-circle-info"
    end
  end

  def page_title(value = nil)
    content_for(:title, value) if value
    content_for?(:title) ? "#{content_for(:title)} · Holistic Chart" : "Holistic Chart · Holistic Wellness Fitness"
  end
end
