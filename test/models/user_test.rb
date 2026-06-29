require "test_helper"

class UserTest < ActiveSupport::TestCase
  def valid_attrs(overrides = {})
    { first_name: "Ada", last_name: "Lovelace", username: "ada",
      email: "ada@example.com", password: "secret9pass" }.merge(overrides)
  end

  test "is valid with required attributes" do
    assert User.new(valid_attrs).valid?
  end

  test "requires a 10+ character password" do
    user = User.new(valid_attrs(password: "abc123"))
    assert_not user.valid?
    assert_includes user.errors[:password], "must be at least 10 characters"
  end

  test "rejects common passwords even when long enough" do
    user = User.new(valid_attrs(password: "password123"))
    assert_not user.valid?
    assert_includes user.errors[:password], "is too common — please choose something harder to guess"
  end

  test "enforces unique username and email case-insensitively" do
    User.create!(valid_attrs)
    dup = User.new(valid_attrs(username: "ADA", email: "ADA@example.com"))
    assert_not dup.valid?
  end

  test "builds a health profile after creation" do
    user = User.create!(valid_attrs)
    assert user.health_profile.present?
  end

  test "member_id is a zero-padded HWF number" do
    user = User.create!(valid_attrs)
    assert_match(/\AHWF-\d{6}\z/, user.member_id)
  end

  test "initials and full name" do
    user = User.new(valid_attrs)
    assert_equal "AL", user.initials
    assert_equal "Ada Lovelace", user.full_name
  end

  test "current_weight prefers the latest check-in weight" do
    user = User.create!(valid_attrs)
    user.health_profile.update!(starting_weight: 200)
    user.checkins.create!(checkin_date: Date.current, weight: 188)
    assert_equal 188.0, user.current_weight.to_f
  end
end
