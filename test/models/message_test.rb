require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @member = User.create!(first_name: "M", last_name: "B", username: "msgmem", email: "m@e.com", password: "password1")
    @admin  = User.create!(first_name: "Ad", last_name: "Min", username: "msgadm", email: "a@e.com", password: "password1", role: "admin")
    @other  = User.create!(first_name: "O", last_name: "T", username: "msgoth", email: "o@e.com", password: "password1")
  end

  test "member may post in their own thread" do
    msg = Message.new(member: @member, sender: @member, body: "hi")
    assert msg.valid?
    assert msg.from_member?
  end

  test "admin may post in any member thread" do
    msg = Message.new(member: @member, sender: @admin, body: "hello")
    assert msg.valid?
    assert msg.from_admin?
  end

  test "a different member cannot post in someone else's thread" do
    msg = Message.new(member: @member, sender: @other, body: "nope")
    assert_not msg.valid?
    assert_includes msg.errors[:sender], "must be the member or an admin"
  end

  test "body is required" do
    assert_not Message.new(member: @member, sender: @member, body: "").valid?
  end
end
