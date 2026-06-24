# Be sure to restart your server when you modify this file.
#
# Restrict powerful browser features the app does not use. Set via default
# response headers so it ships on every HTML response.
Rails.application.config.action_dispatch.default_headers.merge!(
  "Permissions-Policy" => "camera=(), microphone=(), geolocation=(), gyroscope=(), usb=(), payment=(), fullscreen=(self)"
)
