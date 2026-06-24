# Be sure to restart your server when you modify this file.
#
# Harden the session cookie: HttpOnly (default), Lax SameSite to blunt CSRF, and
# Secure-only in production so it is never sent over plain HTTP.
Rails.application.config.session_store :cookie_store,
                                       key: "_holistic_chart_session",
                                       same_site: :lax,
                                       secure: Rails.env.production?
