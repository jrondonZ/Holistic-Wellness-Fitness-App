require "test_helper"

# End-to-end coverage of the Sage assistant endpoint: auth gating, validation,
# a real grounded reply, and that the access trail is written.
class SageChatTest < ActionDispatch::IntegrationTest
  setup do
    @member = User.create!(first_name: "Sage", last_name: "Tester", username: "sagemem",
                           email: "sagemem@e.com", password: "wellpass2026")
    @member.accept_legal!
  end

  def login
    post login_path, params: { username: @member.username, password: "wellpass2026" }
  end

  test "requires authentication" do
    post "/api/ai/chat", params: { message: "hi" }, as: :json
    assert_response :redirect
  end

  test "returns a grounded wellness reply for a signed-in member" do
    login
    assert_difference -> { AuditLog.where(action: "ai_chat").count }, 1 do
      post "/api/ai/chat", params: { message: "how much protein should I eat?" }, as: :json
    end
    assert_response :success
    body = JSON.parse(response.body)
    assert body["reply"].present?
    assert_equal "grounded", body["provider"]
  end

  test "escalates a crisis message to 911 / 988" do
    login
    post "/api/ai/chat", params: { message: "I'm having chest pain right now" }, as: :json
    assert_response :success
    assert_match(/911/, JSON.parse(response.body)["reply"])
  end

  test "rejects a blank message" do
    login
    post "/api/ai/chat", params: { message: "  " }, as: :json
    assert_response :bad_request
  end

  test "rejects an over-long message" do
    login
    post "/api/ai/chat", params: { message: "a" * 1001 }, as: :json
    assert_response :unprocessable_entity
  end
end
