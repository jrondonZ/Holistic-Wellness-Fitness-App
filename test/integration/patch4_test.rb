require "test_helper"

class Patch4Test < ActionDispatch::IntegrationTest
  setup do
    ActionMailer::Base.deliveries.clear
    @owner = User.create!(first_name: "Own", last_name: "Er", username: "own4",
                          email: "own4@example.com", password: "wellpass2026", role: "owner")
    @prov1 = User.create!(first_name: "Cee", last_name: "Coach", username: "prov1",
                          email: "prov1@example.com", password: "wellpass2026", role: "admin", title: "Nutrition")
    @prov2 = User.create!(first_name: "Em", last_name: "Trainer", username: "prov2",
                          email: "prov2@example.com", password: "wellpass2026", role: "admin", title: "Trainer")
    @member = User.create!(first_name: "Mem", last_name: "Ber", username: "mem4",
                           email: "mem4@example.com", password: "wellpass2026")
    [ @prov1, @prov2, @member ].each(&:accept_legal!)
  end

  def login(user, password = "wellpass2026")
    post login_path, params: { username: user.username, password: password }
  end

  # --------------------------------------------- owner assigns providers
  test "owner assigns a provider, which notifies and restricts member messaging" do
    login(@owner)
    assert_difference [ "CareAssignment.count", "@member.notifications.count" ], 1 do
      post admin_user_care_assignments_path(@member), params: { provider_id: @prov1.id }
    end
    assert @member.providers.exists?(id: @prov1.id)

    # Now the member can message the assigned provider…
    login(@member)
    post message_thread_path(@prov1), params: { message: { body: "hello" } }
    assert_equal @prov1, Message.last.provider
    # …but not an unassigned one.
    assert_no_difference "Message.count" do
      post message_thread_path(@prov2), params: { message: { body: "nope" } }
    end
    assert_redirected_to messages_path
  end

  test "messaging a provider notifies that provider" do
    CareAssignment.create!(member: @member, provider: @prov1)
    login(@member)
    assert_difference -> { @prov1.notifications.count }, 1 do
      post message_thread_path(@prov1), params: { message: { body: "Question" } }
    end
  end

  # --------------------------------------------- owner full user CRUD
  test "owner can create, edit and delete users" do
    login(@owner)

    assert_difference "User.count", 1 do
      post admin_users_path, params: { user: {
        first_name: "Brand", last_name: "New", username: "brandnew", email: "bn@example.com",
        role: "admin", password: "wellpass2026", password_confirmation: "wellpass2026"
      } }
    end
    created = User.find_by(username: "brandnew")
    assert created.admin?

    patch admin_user_path(created), params: { user: { first_name: "Renamed", role: "member" } }
    assert_equal "Renamed", created.reload.first_name
    assert created.member?

    assert_difference "User.count", -1 do
      delete admin_user_path(created)
    end
  end

  test "owner cannot delete the owner account or themselves" do
    login(@owner)
    assert_no_difference "User.count" do
      delete admin_user_path(@owner)
    end
    assert User.exists?(@owner.id)
  end

  test "non-owner admins cannot manage users" do
    login(@prov1)
    get new_admin_user_path
    assert_redirected_to admin_root_path
    assert_no_difference "User.count" do
      post admin_users_path, params: { user: { first_name: "x", username: "x", email: "x@e.com", password: "wellpass2026", password_confirmation: "wellpass2026" } }
    end
  end

  # --------------------------------------------- settings / password
  test "member can change their password with the current one" do
    login(@member)
    patch settings_password_path, params: {
      current_password: "wellpass2026", password: "newsecret2026", password_confirmation: "newsecret2026"
    }
    assert_redirected_to settings_path
    assert @member.reload.authenticate("newsecret2026")
  end

  test "wrong current password is rejected" do
    login(@member)
    patch settings_password_path, params: {
      current_password: "wrong", password: "newsecret2026", password_confirmation: "newsecret2026"
    }
    assert_not @member.reload.authenticate("newsecret2026")
  end

  test "profile update does not allow role escalation" do
    login(@member)
    patch settings_path, params: { user: { first_name: "Updated", role: "owner" } }
    assert_equal "Updated", @member.reload.first_name
    assert @member.member?
  end

  # --------------------------------------------- forgot password
  test "forgot-password sends a link and the token resets the password" do
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post password_resets_path, params: { email: @member.email }
    end
    assert_redirected_to login_path

    token = @member.generate_token_for(:password_reset)
    patch password_reset_path(token), params: { password: "freshpass2026", password_confirmation: "freshpass2026" }
    assert_redirected_to login_path
    assert @member.reload.authenticate("freshpass2026")
  end

  test "forgot-password does not reveal whether an email exists" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post password_resets_path, params: { email: "nobody@nowhere.com" }
    end
    assert_redirected_to login_path
  end

  # --------------------------------------------- notifications
  test "notifications can be read individually and all at once" do
    n1 = Notification.notify(@member, kind: "test", title: "One", url: "/dashboard")
    Notification.notify(@member, kind: "test", title: "Two")
    login(@member)

    get notifications_path
    assert_response :success

    patch read_notification_path(n1)
    assert n1.reload.read?

    patch read_all_notifications_path
    assert_equal 0, @member.notifications.unread.count
  end

  # --------------------------------------------- rendering of new screens
  test "new screens render without errors" do
    login(@member)
    [ settings_path, messages_path, message_thread_path(@prov1), notifications_path,
      new_password_reset_path ].each do |path|
      get path
      assert_response :success, "expected 200 for #{path}"
    end
    get edit_password_reset_path(@member.generate_token_for(:password_reset))
    assert_response :success

    login(@owner)
    [ admin_users_path, new_admin_user_path, edit_admin_user_path(@member),
      admin_team_path, admin_user_path(@member) ].each do |path|
      get path
      assert_response :success, "expected 200 for #{path}"
    end
    assert_match "Care team", response.body # provider-assignment widget on member chart
  end

  # --------------------------------------------- tutorial
  test "member can complete and restart the tutorial" do
    login(@member)
    assert @member.needs_tutorial?
    post complete_tutorial_path
    assert_response :success
    assert_not @member.reload.needs_tutorial?

    delete restart_tutorial_path
    assert @member.reload.needs_tutorial?
  end
end
