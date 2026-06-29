require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  def member(suffix = "1")
    User.create!(first_name: "M", last_name: "B", username: "audmem#{suffix}",
                 email: "audmem#{suffix}@e.com", password: "wellpass2026")
  end

  test "record! writes an entry with actor, subject, resource and request data" do
    actor   = member("a")
    subject = member("b")
    req     = Struct.new(:remote_ip, :user_agent).new("203.0.113.5", "TestAgent/1.0")

    log = AuditLog.record!(action: :view, actor: actor, subject: subject,
                           resource: subject.health_profile, request: req,
                           metadata: { area: "chart" })

    assert log.persisted?
    assert_equal "view", log.action
    assert_equal actor.id, log.actor_id
    assert_equal subject.id, log.subject_id
    assert_equal "HealthProfile", log.resource_type
    assert_equal subject.health_profile.id, log.resource_id
    assert_equal "203.0.113.5", log.ip_address
    assert_equal({ "area" => "chart" }, log.metadata)
  end

  test "action is required" do
    assert_raises(ActiveRecord::RecordInvalid) { AuditLog.create!(action: nil) }
  end

  test "record! never raises — a logging failure must not break the request" do
    # A request object that explodes when read should be swallowed, returning nil.
    bad_req = Object.new
    bad_req.define_singleton_method(:remote_ip) { raise "kaboom" }
    bad_req.define_singleton_method(:user_agent) { "x" }
    assert_nothing_raised do
      assert_nil AuditLog.record!(action: :view, request: bad_req)
    end
  end

  test "scopes filter by subject and actor" do
    actor = member("c")
    subj  = member("d")
    AuditLog.record!(action: :view, actor: actor, subject: subj)
    assert_equal 1, AuditLog.for_subject(subj).count
    assert_equal 1, AuditLog.by_actor(actor).count
  end
end
