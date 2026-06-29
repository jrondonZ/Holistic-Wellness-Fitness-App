require "test_helper"

# Covers the adaptive Sage provider chain: configuration/precedence, the
# guaranteed grounded fallback, graceful fall-through when a networked provider
# is down, and that the engine never raises or returns blank.
class SageEngineTest < ActiveSupport::TestCase
  # Run with a clean slate so a real GROQ_API_KEY / OLLAMA_URL in the environment
  # can't make these tests hit the network or flake.
  CLEAR = {
    "SAGE_PROVIDERS"    => nil,
    "GROQ_API_KEY"      => nil,
    "LOCAL_LLM_URL"     => nil,
    "OLLAMA_URL"        => nil,
    "LOCAL_LLM_API_KEY" => nil,
    "LOCAL_LLM_MODEL"   => nil
  }.freeze

  def with_env(overrides)
    saved = {}
    overrides.each do |k, v|
      saved[k] = ENV[k]
      v.nil? ? ENV.delete(k) : ENV[k] = v
    end
    yield
  ensure
    saved.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  # ── Configuration / precedence ────────────────────────────────────────────
  test "defaults to grounded-only with nothing configured (free-tier + PHI safe)" do
    with_env(CLEAR) do
      assert_equal [ :grounded ], Sage::Config.provider_chain
      assert Sage::Config.fully_local?, "grounded-only must count as fully local"
    end
  end

  test "a local LLM URL puts your own model first and stays fully local" do
    with_env(CLEAR.merge("LOCAL_LLM_URL" => "http://localhost:11434/v1")) do
      assert_equal [ :local_llm, :grounded ], Sage::Config.provider_chain
      assert Sage::Providers::LocalLlm.new.available?
      assert Sage::Config.fully_local?
    end
  end

  test "OLLAMA_URL is honored and trailing slashes are trimmed" do
    with_env(CLEAR.merge("OLLAMA_URL" => "http://host:11434/v1/")) do
      assert_equal "http://host:11434/v1", Sage::Config.local_llm_url
      assert_includes Sage::Config.provider_chain, :local_llm
    end
  end

  test "Groq joins the chain only when a key is present and is not fully local" do
    with_env(CLEAR) { refute_includes Sage::Config.provider_chain, :groq }
    with_env(CLEAR.merge("GROQ_API_KEY" => "test-key")) do
      assert_equal [ :groq, :grounded ], Sage::Config.provider_chain
      refute Sage::Config.fully_local?, "a hosted provider must not count as fully local"
    end
  end

  test "full chain orders local before groq before grounded" do
    with_env(CLEAR.merge("LOCAL_LLM_URL" => "http://localhost:11434/v1", "GROQ_API_KEY" => "k")) do
      assert_equal [ :local_llm, :groq, :grounded ], Sage::Config.provider_chain
    end
  end

  test "explicit SAGE_PROVIDERS overrides, sanitizes, and still guarantees grounded" do
    with_env(CLEAR.merge("SAGE_PROVIDERS" => "groq, bogus , local_llm")) do
      assert_equal [ :groq, :local_llm, :grounded ], Sage::Config.provider_chain
    end
  end

  # ── Engine behavior ───────────────────────────────────────────────────────
  test "always answers via grounded when nothing else is configured" do
    with_env(CLEAR) do
      res = Sage::Engine.new.reply("give me some wellness tips", context: {}, history: [])
      assert_equal :grounded, res.provider
      assert res.text.present?
    end
  end

  test "routes urgent/crisis messages to 911 / 988 guidance" do
    with_env(CLEAR) do
      res = Sage::Engine.new.reply("I'm having chest pain right now", context: {}, history: [])
      assert_match(/911/, res.text)
      res2 = Sage::Engine.new.reply("I want to harm myself", context: {}, history: [])
      assert_match(/988/, res2.text)
    end
  end

  test "personalizes the greeting from chart context" do
    with_env(CLEAR) do
      res = Sage::Engine.new.reply("hi", context: { first_name: "Ada", primary_goal: "Gut healing" }, history: [])
      assert_match(/Ada/, res.text)
    end
  end

  test "never raises and never returns blank, for any input" do
    with_env(CLEAR) do
      [ "", "asdkjfh", "🥗", "how much protein should I eat?", "I keep waking up tired" ].each do |m|
        res = Sage::Engine.new.reply(m, context: {}, history: [])
        assert res.text.present?, "blank reply for #{m.inspect}"
      end
    end
  end

  test "falls through to grounded when the local endpoint is unreachable" do
    # Port 1 refuses instantly → provider returns nil → chain lands on grounded.
    with_env(CLEAR.merge("LOCAL_LLM_URL" => "http://127.0.0.1:1/v1")) do
      res = Sage::Engine.new.reply("wellness tips", context: {}, history: [])
      assert_equal :grounded, res.provider
      assert res.text.present?
    end
  end
end
