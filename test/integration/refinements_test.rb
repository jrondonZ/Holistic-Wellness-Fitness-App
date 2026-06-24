require "test_helper"

class RefinementsTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(first_name: "Jo", last_name: "Owner", username: "owner1",
                          email: "owner1@example.com", password: "password1", role: "owner")
    @admin = User.create!(first_name: "Ada", last_name: "Min", username: "admin2",
                          email: "admin2@example.com", password: "password1", role: "admin")
    @member = User.create!(first_name: "New", last_name: "Member", username: "newbie",
                           email: "newbie@example.com", password: "password1")
    [ @owner, @admin ].each(&:accept_legal!)
  end

  def login(user, password = "password1")
    post login_path, params: { username: user.username, password: password }
  end

  # ---------------------------------------------------------- onboarding/legal
  test "new member is gated into onboarding until accepting legal" do
    login(@member)
    assert_redirected_to onboarding_path

    get dashboard_path
    assert_redirected_to onboarding_path

    # Refusing acceptance keeps them on onboarding.
    patch onboarding_path, params: { accept_terms: "1" }
    assert_redirected_to onboarding_path
    assert_not @member.reload.accepted_current_legal?

    # Accepting both unlocks the app.
    patch onboarding_path, params: { accept_terms: "1", accept_privacy: "1" }
    assert_redirected_to dashboard_path
    assert @member.reload.accepted_current_legal?
    assert @member.terms_accepted_at.present?

    get dashboard_path
    assert_response :success
  end

  test "legal pages are public" do
    get terms_path
    assert_response :success
    assert_match "Terms of Use", response.body
    get privacy_path
    assert_response :success
    assert_match "Privacy Policy", response.body
  end

  # ------------------------------------------------------------- role routing
  test "staff land in the admin portal after login" do
    login(@owner)
    assert_redirected_to admin_root_path
    login(@admin)
    assert_redirected_to admin_root_path
  end

  # --------------------------------------------------------------- owner/team
  test "owner can add, promote and demote admins but not change the owner" do
    login(@owner)

    assert_difference -> { User.staff.count }, 1 do
      post admin_team_path, params: { user: {
        first_name: "Pat", last_name: "Coach", username: "patcoach",
        email: "pat@example.com", password: "password1", password_confirmation: "password1"
      } }
    end
    assert User.find_by(username: "patcoach").admin?

    # Promote a member
    patch admin_team_member_path(@member), params: { role: "admin" }
    assert @member.reload.admin?

    # Demote an admin back to member
    delete admin_team_member_path(@admin)
    assert @member.reload # sanity
    assert @admin.reload.member?

    # The owner cannot be demoted via team management
    patch admin_team_member_path(@owner), params: { role: "member" }
    assert @owner.reload.owner?
  end

  test "non-owner admins cannot reach team management" do
    login(@admin)
    get admin_team_path
    assert_redirected_to admin_root_path
    post admin_team_path, params: { user: { first_name: "x" } }
    assert_redirected_to admin_root_path
  end

  test "members self-signup cannot assign themselves a role" do
    assert_difference "User.count", 1 do
      post signup_path, params: { user: {
        first_name: "Sneaky", last_name: "User", username: "sneaky",
        email: "sneaky@example.com", password: "password1", password_confirmation: "password1",
        role: "owner"
      } }
    end
    assert User.find_by(username: "sneaky").member?, "role must not be mass-assignable on signup"
  end

  # ------------------------------------------------------------- messaging
  test "member messages carry a topic" do
    login(@admin) # ensure a staff recipient exists
    delete logout_path
    login(@owner) # accepted; just to vary
    delete logout_path
    @member.accept_legal!
    login(@member)
    post messages_path, params: { message: { body: "Question about my plan", topic: "Nutrition" } }
    assert_equal "Nutrition", Message.last.topic
    assert_equal @member, Message.last.member
  end

  # --------------------------------------------------------------- rendering
  test "onboarding walkthrough renders for a new member" do
    login(@member)
    get onboarding_path
    assert_response :success
    assert_match "Welcome", response.body
    assert_match "Accept &amp; enter", response.body
  end

  test "owner team page and new-service form render" do
    login(@owner)
    get admin_team_path
    assert_response :success
    assert_match "Care team", response.body
    get new_admin_service_path
    assert_response :success
    assert_match "New service", response.body
  end

  # -------------------------------------------------------------- security
  test "a strict content security policy is sent" do
    get login_path
    csp = response.headers["Content-Security-Policy"]
    assert csp.present?, "expected a CSP header"
    assert_includes csp, "https://cdn.jsdelivr.net"
    assert_includes csp, "'nonce-"
    assert_includes csp, "object-src 'none'"
    assert_includes csp, "frame-ancestors 'self'"
  end

  test "importmap script tags receive a CSP nonce" do
    get login_path
    # Every <script> emitted by the importmap must carry a nonce or it would be
    # blocked by the strict policy.
    assert_match(/<script[^>]*type="importmap"[^>]*nonce="/, response.body)
  end

  test "permissions policy header is sent" do
    get login_path
    assert response.headers["Permissions-Policy"].present?
  end
end
