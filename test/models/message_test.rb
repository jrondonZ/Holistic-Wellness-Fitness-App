require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @member = User.create!(first_name: "M", last_name: "B", username: "msgmem", email: "m@e.com", password: "password1")
    @admin  = User.create!(first_name: "Ad", last_name: "Min", username: "msgadm", email: "a@e.com", password: "password1", role: "admin")
    @other  = User.create!(first_name: "O", last_name: "T", username: "msgoth", email: "o@e.com", password: "password1")
  end

  test "member may post in their own thread with a provider" do
    msg = Message.new(member: @member, sender: @member, provider: @admin, body: "hi")
    assert msg.valid?
    assert msg.from_member?
  end

  test "admin may post in any member thread" do
    msg = Message.new(member: @member, sender: @admin, provider: @admin, body: "hello")
    assert msg.valid?
    assert msg.from_admin?
  end

  test "a different member cannot post in someone else's thread" do
    msg = Message.new(member: @member, sender: @other, provider: @admin, body: "nope")
    assert_not msg.valid?
    assert_includes msg.errors[:sender], "must be the member or a care-team member"
  end

  test "the provider must be staff" do
    msg = Message.new(member: @member, sender: @member, provider: @other, body: "hi")
    assert_not msg.valid?
    assert_includes msg.errors[:provider], "must be a staff member"
  end

  test "body is required" do
    assert_not Message.new(member: @member, sender: @member, provider: @admin, body: "").valid?
  end
end
