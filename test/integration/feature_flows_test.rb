require "test_helper"

class FeatureFlowsTest < ActionDispatch::IntegrationTest
  setup do
    @member = User.create!(first_name: "Mem", last_name: "Ber", username: "member1",
                           email: "member1@example.com", password: "password1")
    @admin = User.create!(first_name: "Ada", last_name: "Min", username: "admin1",
                          email: "admin1@example.com", password: "password1", role: "admin")
    @service = Service.create!(name: "Personal Training", category: "Personal Training",
                               duration_min: 60, price_cents: 7500, icon: "fa-dumbbell")
    @training = TrainingModule.create!(slug: "hipaa-privacy", title: "HIPAA Privacy",
                                       summary: "s", body: "## A\n\nbody",
                                       quiz: [ { "q" => "PHI?", "options" => %w[No Yes], "answer" => 1 } ])
  end

  def login(user, password = "password1")
    post login_path, params: { username: user.username, password: password }
  end

  # ----------------------------------------------------------------- member
  test "member can browse scheduling and book an appointment" do
    login(@member)
    get services_path
    assert_response :success
    assert_match "Book a session", response.body

    get service_path(@service)
    assert_response :success

    get new_appointment_path(service_id: @service.slug)
    assert_response :success

    assert_difference "Appointment.count", 1 do
      post appointments_path, params: { appointment: {
        service_id: @service.id, scheduled_at: 3.days.from_now.change(hour: 10), mode: "virtual", reason: "Test"
      } }
    end
    assert_response :redirect
  end

  test "member can view and complete training" do
    login(@member)
    get trainings_path
    assert_response :success
    assert_match "Required training", response.body

    get training_path(@training)
    assert_response :success

    assert_difference "TrainingCompletion.count", 1 do
      post complete_training_path(@training), params: { acknowledge: "1", signature: "Mem Ber", answers: { "0" => "1" } }
    end
    assert @member.training_complete?("hipaa-privacy")
  end

  test "member can message the care team" do
    login(@member)
    get messages_path
    assert_response :success

    assert_difference "Message.count", 1 do
      post messages_path, params: { message: { body: "Hi team" } }
    end
    assert_equal @member, Message.last.member
    assert_equal @member, Message.last.sender
  end

  test "appointments and BMI/dashboard render" do
    login(@member)
    get dashboard_path
    assert_response :success
    assert_match "BMI", response.body
    get appointments_path
    assert_response :success
  end

  # ------------------------------------------------------------------ admin
  test "admin portal pages render" do
    login(@admin)
    [ admin_root_path, admin_users_path, admin_user_path(@member), admin_appointments_path,
      admin_conversations_path, admin_conversation_path(@member), admin_services_path,
      edit_admin_service_path(@service), admin_analytics_path ].each do |path|
      get path
      assert_response :success, "expected 200 for #{path}"
    end
    assert_match "Diagnostic flags", get(admin_user_path(@member)) && response.body
  end

  test "admin can reply, assess, and manage an appointment" do
    appt = @member.appointments.create!(service: @service, scheduled_at: 2.days.from_now, status: "requested")
    login(@admin)

    assert_difference "Message.count", 1 do
      post reply_admin_conversation_path(@member), params: { message: { body: "Reply" } }
    end
    assert Message.last.from_admin?

    assert_difference "Assessment.count", 1 do
      post admin_user_assessments_path(@member), params: { assessment: { title: "Note", category: "General", severity: "info" } }
    end

    patch admin_appointment_path(appt), params: { appointment: { status: "confirmed", mode: "virtual", meeting_url: "https://meet.example.com/x" } }
    assert_response :redirect
    assert_equal "confirmed", appt.reload.status
    assert appt.confirmed_at.present?
  end

  # ------------------------------------------------------------------ guard
  test "members are blocked from the admin portal" do
    login(@member)
    get admin_root_path
    assert_redirected_to dashboard_path
  end

  test "logged-out visitors are sent to login" do
    get admin_root_path
    assert_redirected_to login_path
    get appointments_path
    assert_redirected_to login_path
  end
end
