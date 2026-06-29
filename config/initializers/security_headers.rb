# Hardening: security-related response headers applied to every response.
#
# These reduce clickjacking, MIME-sniffing, referrer leakage, and limit how
# freely other origins can embed, read, or hotlink the app's resources — raising
# the bar for a portal that holds protected health information. They are
# defense-in-depth on top of force_ssl (HSTS), the Content Security Policy, the
# hardened session cookie, and Rack::Attack.
#
# NOTE: Cross-Origin-Embedder-Policy is intentionally NOT set to "require-corp"
# because the chart embeds third-party resources (Bootstrap, Chart.js, Font
# Awesome, YouTube workout videos); requiring CORP on all of them would break the
# UI. COOP + CORP below still isolate the app's own browsing context.
Rails.application.config.action_dispatch.default_headers.merge!(
  "X-Frame-Options"                   => "DENY",
  "X-Content-Type-Options"            => "nosniff",
  "X-Permitted-Cross-Domain-Policies" => "none",
  "Referrer-Policy"                   => "strict-origin-when-cross-origin",
  "Cross-Origin-Opener-Policy"        => "same-origin",
  "Cross-Origin-Resource-Policy"      => "same-origin",
  "X-Download-Options"                => "noopen",
  "X-DNS-Prefetch-Control"            => "off"
)
