require "test_helper"

class RefinementsTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(first_name: "Jo", last_name: "Owner", username: "owner1",
                          email: "owner1@example.com", password: "wellpass2026", role: "owner")
    @admin = User.create!(first_name: "Ada", last_name: "Min", username: "admin2",
                          email: "admin2@example.com", password: "wellpass2026", role: "admin")
    @member = User.create!(first_name: "New", last_name: "Member", username: "newbie",
                           email: "newbie@example.com", password: "wellpass2026")
    [ @owner, @admin ].each(&:accept_legal!) # @member intentionally NOT accepted
  end

  def login(user, password = "wellpass2026")
    post login_path, params: { username: user.username, password: password }
  end

  # ---------------------------------------------------------- legal gate modal
  test "members must accept the legal modal before acting" do
    login(@member)
    get dashboard_path
    assert_response :success
    assert_match "before you continue", response.body # the blocking modal

    # Mutations are blocked until acceptance.
    assert_no_difference "Checkin.count" do
      post checkins_path, params: { checkin: { checkin_date: Date.current, mood: 3 } }
    end
    assert_redirected_to dashboard_path

    # Accepting both unlocks the app.
    post accept_legal_path, params: { accept_terms: "1", accept_privacy: "1" }
    assert_redirected_to dashboard_path
    assert @member.reload.accepted_current_legal?
  end

  test "the owner is exempt from the legal gate" do
    fresh_owner = User.create!(first_name: "Top", last_name: "Boss", username: "topboss",
                               email: "top@example.com", password: "wellpass2026", role: "owner")
    login(fresh_owner)
    get admin_root_path
    assert_response :success
    assert_no_match "before you continue", response.body
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
        email: "pat@example.com", password: "wellpass2026", password_confirmation: "wellpass2026"
      } }
    end
    assert User.find_by(username: "patcoach").admin?

    patch admin_team_member_path(@member), params: { role: "admin" }
    assert @member.reload.admin?

    delete admin_team_member_path(@admin)
    assert @admin.reload.member?

    patch admin_team_member_path(@owner), params: { role: "member" }
    assert @owner.reload.owner?
  end

  test "non-owner admins cannot reach team management" do
    login(@admin)
    get admin_team_path
    assert_redirected_to admin_root_path
  end

  test "members self-signup cannot assign themselves a role" do
    post signup_path, params: { user: {
      first_name: "Sneaky", last_name: "User", username: "sneaky",
      email: "sneaky@example.com", password: "wellpass2026", password_confirmation: "wellpass2026", role: "owner"
    } }
    assert User.find_by(username: "sneaky").member?, "role must not be mass-assignable on signup"
  end

  # ------------------------------------------------------------- messaging
  test "member messages are scoped to a chosen provider" do
    @member.accept_legal!
    login(@member)
    get message_thread_path(@admin)
    assert_response :success
    post message_thread_path(@admin), params: { message: { body: "hi", topic: "Nutrition" } }
    assert_equal @admin, Message.last.provider
  end

  # -------------------------------------------------------------- security
  test "a strict content security policy is sent" do
    get login_path
    csp = response.headers["Content-Security-Policy"]
    assert csp.present?
    assert_includes csp, "https://cdn.jsdelivr.net"
    assert_includes csp, "'nonce-"
    assert_includes csp, "object-src 'none'"
    assert_includes csp, "frame-ancestors 'self'"
  end

  test "importmap script tags receive a CSP nonce" do
    get login_path
    assert_match(/<script[^>]*type="importmap"[^>]*nonce="/, response.body)
  end

  test "permissions policy header is sent" do
    get login_path
    assert response.headers["Permissions-Policy"].present?
  end
end
