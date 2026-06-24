# Be sure to restart your server when you modify this file.
#
# Application-wide Content Security Policy. Scripts are restricted to our own
# origin plus the specific CDNs we load (Bootstrap, Chart.js, AOS) and use a
# per-request nonce; inline event handlers and unknown script origins are blocked.
# See https://guides.rubyonrails.org/security.html#content-security-policy-header
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri    :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.media_src   :self
    # Scripts: our origin + jsDelivr (Bootstrap, Chart.js) + unpkg (AOS). A nonce
    # is added automatically (see below); inline handlers are not allowed.
    policy.script_src  :self, "https://cdn.jsdelivr.net", "https://unpkg.com"
    # Styles: inline allowed because the UI uses inline style attributes; restricted
    # to our origin + the CSS CDNs we load.
    policy.style_src   :self, :unsafe_inline,
                       "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com",
                       "https://fonts.googleapis.com", "https://unpkg.com"
    policy.connect_src :self, "https://cdn.jsdelivr.net"
    # Only our own pages and YouTube (workout video embeds) may be framed.
    policy.frame_src   "https://www.youtube.com", "https://www.youtube-nocookie.com"
    policy.frame_ancestors :self
    policy.form_action :self
  end

  # Generate a per-request nonce and attach it to script tags (importmap, modules).
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
