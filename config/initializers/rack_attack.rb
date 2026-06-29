# Rack::Attack — rate limiting, brute-force throttling, and abuse blocking.
#
# A health record is a high-value target, so the defaults here are strict but
# tuned so a real member never notices. Throttle state lives in Rails.cache; on a
# horizontally-scaled deploy use a shared cache (Redis/Memcached/Solid Cache) so
# limits hold across processes rather than being multiplied by the worker count.
require "ipaddr"

class Rack::Attack
  Rack::Attack.cache.store = Rails.cache

  # ── Safelists ──────────────────────────────────────────────────────────────
  # Never throttle loopback (dev, health checks, internal probes).
  safelist("allow-localhost") do |req|
    [ "127.0.0.1", "::1" ].include?(req.ip)
  end

  # Static assets and the health check are cheap and high-volume — skip them.
  safelist("allow-assets") do |req|
    req.path.start_with?("/assets/", "/up") || req.path == "/favicon.ico"
  end

  # ── General flood protection ────────────────────────────────────────────────
  # A generous ceiling normal browsing never approaches, but that stops a single
  # host from hammering the app.
  throttle("req/ip", limit: 300, period: 5.minutes, &:ip)

  # ── Authentication: brute-force / credential stuffing ────────────────────────
  # Per-IP cap on login attempts.
  throttle("login/ip", limit: 10, period: 60.seconds) do |req|
    req.ip if req.path == "/login" && req.post?
  end

  # Per-identifier cap — stops slow, distributed guessing against one account.
  throttle("login/identifier", limit: 5, period: 60.seconds) do |req|
    if req.path == "/login" && req.post?
      req.params.dig("username").to_s.downcase.strip.presence
    end
  end

  # Cap new-account creation per IP (spam / enumeration).
  throttle("signup/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/signup" && req.post?
  end

  # Cap password-reset requests per IP (prevents reset-email bombing).
  throttle("pwreset/ip", limit: 5, period: 15.minutes) do |req|
    req.ip if req.path == "/password_resets" && req.post?
  end

  # ── Sage AI chat: per-IP defense-in-depth (the controller also caps per user) ─
  throttle("sage/ip", limit: 40, period: 1.minute) do |req|
    req.ip if req.path == "/api/ai/chat" && req.post?
  end

  # ── Write endpoints: throttle mutating requests per IP ───────────────────────
  throttle("writes/ip", limit: 80, period: 1.minute) do |req|
    if %w[POST PUT PATCH DELETE].include?(req.request_method) &&
       !req.path.start_with?("/login", "/signup", "/password_resets", "/api/ai")
      req.ip
    end
  end

  # ── Block common vulnerability probes (.env, .git, wp-admin, traversal) ──────
  # Fail2Ban: a few probes from an IP earns a temporary ban.
  blocklist("block-probes") do |req|
    Rack::Attack::Fail2Ban.filter("probes-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      path = req.path.to_s.downcase
      path.match?(%r{\A/(\.env|\.git|wp-admin|wp-login|xmlrpc\.php|vendor/phpunit)}) ||
        path.end_with?(".php", ".asp", ".aspx") ||
        path.include?("../") || path.include?("..%2f")
    end
  end

  # ── Responses ────────────────────────────────────────────────────────────────
  self.throttled_responder = lambda do |req|
    match       = req.env["rack.attack.match_data"] || {}
    period      = match[:period].to_i
    retry_after = period.positive? ? period.to_s : "60"
    headers     = { "Content-Type" => "application/json", "Retry-After" => retry_after }
    body        = { error: "Too many requests — please slow down and try again in a moment." }.to_json
    [ 429, headers, [ body ] ]
  end

  self.blocklisted_responder = lambda do |_req|
    [ 403, { "Content-Type" => "text/plain" }, [ "Forbidden\n" ] ]
  end
end

# Log throttles/blocks so abuse is visible without leaking details to clients.
ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
  req = payload[:request]
  Rails.logger.warn("[Rack::Attack] throttled #{req.env['rack.attack.matched']} ip=#{req.ip} path=#{req.path}")
end
