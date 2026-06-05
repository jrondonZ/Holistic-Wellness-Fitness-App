require "test_helper"

class HealthProfileTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(first_name: "Sam", last_name: "Lee", username: "sam",
                         email: "sam@example.com", password: "secret9")
    @profile = @user.health_profile
  end

  test "computes BMI and category" do
    @profile.update!(height_in: 67)
    assert_equal 28.2, @profile.bmi(180)
    assert_equal "Overweight", @profile.bmi_category(180)
  end

  test "age is derived from date of birth" do
    @profile.update!(date_of_birth: 30.years.ago.to_date)
    assert_equal 30, @profile.age
  end

  test "height display formats feet and inches" do
    @profile.update!(height_in: 67)
    assert_equal "5'7\"", @profile.height_display
  end

  test "goal progress is clamped between 0 and 100" do
    @profile.update!(starting_weight: 185, goal_weight: 160)
    assert_equal 50, @profile.goal_progress(172.5)
    assert_equal 100, @profile.goal_progress(150) # past goal clamps to 100
    assert_equal 0, @profile.goal_progress(190)   # heavier than start clamps to 0
  end

  test "target calories subtracts a deficit for weight loss" do
    @profile.update!(height_in: 67, sex: "Female", date_of_birth: 30.years.ago.to_date,
                     activity_level: "Moderately active", primary_goal: "Weight loss")
    maintenance = @profile.estimated_maintenance_calories(170)
    assert_operator maintenance, :>, 0
    assert_equal maintenance - 500, @profile.target_calories(170)
  end

  test "target calories falls back to a default without data" do
    assert_equal 2000, @profile.target_calories
  end
end
