require "test_helper"

class CheckinTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(first_name: "Pat", last_name: "Kim", username: "pat",
                         email: "pat@example.com", password: "secret9pass")
  end

  test "one check-in per day per user" do
    @user.checkins.create!(checkin_date: Date.current, mood: 3)
    dup = @user.checkins.new(checkin_date: Date.current, mood: 4)
    assert_not dup.valid?
    assert_includes dup.errors[:checkin_date], "already has a check-in"
  end

  test "scales must be within 1..5" do
    checkin = @user.checkins.new(checkin_date: Date.current, mood: 9)
    assert_not checkin.valid?
  end

  test "blood pressure formatting and category" do
    checkin = @user.checkins.new(checkin_date: Date.current, systolic: 118, diastolic: 76)
    assert_equal "118/76", checkin.blood_pressure
    assert_equal "Normal", checkin.bp_category
  end

  test "wellness score is a 0..100 composite" do
    checkin = @user.checkins.new(checkin_date: Date.current, mood: 5, energy: 5, stress: 1, sleep_hours: 8)
    score = checkin.wellness_score
    assert_operator score, :>=, 0
    assert_operator score, :<=, 100
    assert_equal 100, score
  end

  test "wellness score is nil without inputs" do
    assert_nil @user.checkins.new(checkin_date: Date.current).wellness_score
  end
end
