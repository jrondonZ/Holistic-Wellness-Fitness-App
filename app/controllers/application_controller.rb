class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  # Auto-sign-out, like a clinical portal: an idle window plus a hard ceiling on
  # total session age, both overridable by env for different deployments.
  SESSION_IDLE_TIMEOUT     = (ENV["SESSION_IDLE_TIMEOUT_MIN"].presence || 30).to_i.minutes
  SESSION_ABSOLUTE_TIMEOUT = (ENV["SESSION_ABSOLUTE_TIMEOUT_HOURS"].presence || 12).to_i.hours

  before_action :enforce_session_timeout
  before_action :require_login

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # Expire sessions that have been idle too long or have simply lived too long,
  # so an unattended browser can't be used to reach protected health information.
  def enforce_session_timeout
    return unless session[:user_id]

    now     = Time.current.to_i
    last    = session[:last_seen_at].to_i
    started = session[:logged_in_at].to_i
    idle    = last.positive?    && (now - last)    > SESSION_IDLE_TIMEOUT.to_i
    expired = started.positive? && (now - started) > SESSION_ABSOLUTE_TIMEOUT.to_i

    if idle || expired
      reset_session
      @current_user = nil
      flash[:warning] = "You were signed out after #{idle ? 'a period of inactivity' : 'reaching the maximum session length'} to protect your health information."
      redirect_to login_path
      return
    end

    session[:last_seen_at] = now
  end

  # Append an immutable PHI access entry. Never raises — auditing must not break
  # the request it observes. `subject` defaults to the acting user (self-access).
  def audit!(action, subject: nil, resource: nil, metadata: {})
    AuditLog.record!(
      action:   action,
      actor:    current_user,
      subject:  subject || current_user,
      resource: resource,
      request:  request,
      metadata: metadata
    )
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    flash[:danger] = "Please log in to open your chart."
    redirect_to login_path
  end

  # Where to send a user right after authentication.
  def after_auth_path(user)
    user.staff? ? admin_root_path : dashboard_path
  end

  # Gate the app behind accepting the current legal documents. Instead of a
  # redirect we flag a blocking modal (rendered by the layout) so the user can
  # read and accept in place. The owner is exempt. Mutations are blocked until
  # acceptance; GET requests still render so the modal can appear.
  def enforce_legal_gate
    return unless current_user&.needs_legal?

    @legal_gate = true
    return if request.get? || request.head?

    redirect_to dashboard_path, alert: "Please accept the Terms of Use & Privacy Policy to continue."
  end
  helper_method :legal_gate?

  def legal_gate?
    @legal_gate.present?
  end

  def require_staff
    return if current_user&.staff?

    flash[:danger] = "That area is for the care team only."
    redirect_to(current_user ? dashboard_path : login_path)
  end

  def require_owner
    return if current_user&.owner?

    flash[:danger] = "Only the owner can manage that."
    redirect_to admin_root_path
  end

  def log_in(user)
    session[:user_id] = user.id
    session[:logged_in_at] = Time.current.to_i
    session[:last_seen_at] = Time.current.to_i
    @current_user = user
  end
end
