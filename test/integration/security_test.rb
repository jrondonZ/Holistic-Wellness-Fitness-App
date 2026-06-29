require "test_helper"

# Covers the privacy/security hardening: security response headers, the PHI
# access trail on authentication, and clinical-style session timeout.
class SecurityTest < ActionDispatch::IntegrationTest
  setup do
    @member = User.create!(first_name: "Pat", last_name: "Vault", username: "secmem",
                           email: "secmem@e.com", password: "wellpass2026")
    @member.accept_legal!
  end

  def login
    post login_path, params: { username: @member.username, password: "wellpass2026" }
  end

  test "hardening headers ship on responses" do
    get login_path
    assert_response :success
    assert_equal "DENY",   response.headers["X-Frame-Options"]
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
    assert_equal "strict-origin-when-cross-origin", response.headers["Referrer-Policy"]
    assert_equal "same-origin", response.headers["Cross-Origin-Opener-Policy"]
  end

  test "a successful login is written to the audit trail" do
    assert_difference -> { AuditLog.where(action: "login", subject_id: @member.id).count }, 1 do
      login
    end
  end

  test "a failed login is recorded without storing the password" do
    assert_difference -> { AuditLog.where(action: "login_failed").count }, 1 do
      post login_path, params: { username: @member.username, password: "totally-wrong-xyz" }
    end
    log = AuditLog.where(action: "login_failed").last
    assert_equal @member.username, log.metadata["identifier"]
    refute_includes log.metadata.to_s, "totally-wrong-xyz"
  end

  test "an idle session is signed out before reaching the chart" do
    login
    get dashboard_path
    assert_response :success

    travel (ApplicationController::SESSION_IDLE_TIMEOUT + 1.minute) do
      get dashboard_path
      assert_redirected_to login_path
      assert_match(/inactivity/i, flash[:warning].to_s)
    end
  end
end
