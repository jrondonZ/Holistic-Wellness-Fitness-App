require "test_helper"

class WorkoutTest < ActiveSupport::TestCase
  test "extracts the YouTube id from common URL forms" do
    [
      "https://www.youtube.com/watch?v=v7AYKMP6rOE",
      "https://youtu.be/v7AYKMP6rOE",
      "https://www.youtube.com/embed/v7AYKMP6rOE"
    ].each do |url|
      assert_equal "v7AYKMP6rOE", Workout.new(video_url: url).youtube_id
    end
  end

  test "builds embed and thumbnail urls" do
    workout = Workout.new(video_url: "https://www.youtube.com/watch?v=v7AYKMP6rOE")
    assert_equal "https://www.youtube.com/embed/v7AYKMP6rOE", workout.embed_url
    assert_equal "https://i.ytimg.com/vi/v7AYKMP6rOE/hqdefault.jpg", workout.thumbnail_url
  end

  test "returns nil video urls when blank" do
    workout = Workout.new(video_url: nil)
    assert_nil workout.youtube_id
    assert_nil workout.embed_url
  end

  test "falls back to a default instructor name" do
    assert_equal "Holistic Wellness Fitness", Workout.new.instructor_name
  end
end
