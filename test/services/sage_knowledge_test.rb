require "test_helper"

# Covers the embeddings-grounded brain: the dependency-free hashing retriever,
# the wellness knowledge base's semantic search + vagueness guard, and that the
# grounded engine answers real wellness questions from vetted content (and
# escalates a crisis).
class SageKnowledgeTest < ActiveSupport::TestCase
  # ── Retriever ──────────────────────────────────────────────────────────────
  test "retriever ranks the semantically closest document first" do
    r = Sage::Retriever.new
    r.add(:sleep,   "sleep insomnia rest bedtime wake time melatonin tired")
    r.add(:protein, "protein muscle eggs greek yogurt beans grams per pound")
    r.add(:gut,     "gut digestion bloating fiber fermented microbiome")

    top = r.search("how much protein do I need to build muscle", limit: 1).first
    assert_equal :protein, top[0]
    assert top[1] > 0, "expected a positive similarity score"
  end

  test "embeddings are L2-normalized (self-similarity is ~1)" do
    r = Sage::Retriever.new
    text = "hydration water ounces bodyweight"
    r.add(:h, text)
    assert_in_delta 1.0, r.search(text, limit: 1).first[1], 0.0001
  end

  # ── Knowledge base search ──────────────────────────────────────────────────
  test "answers specific wellness questions from vetted content" do
    {
      "how do I reduce bloating and improve digestion" => /fiber|fermented|gut/i,
      "how much protein should I eat to keep muscle"    => /protein|muscle|gram/i,
      "what can I do to sleep better at night"          => /sleep|wake time|screens|dark/i,
      "how do I start working out and stay consistent"  => /routine|week|progress|consist/i
    }.each do |q, pattern|
      ans = Sage::Knowledge.answer(q)
      assert ans.present?, "no KB answer for #{q.inspect}"
      assert_match pattern, ans, "unexpected KB answer for #{q.inspect}: #{ans}"
    end
  end

  test "self-harm content surfaces the 988 lifeline in the KB entry" do
    assert_match(/988/, Sage::Knowledge.answer("I have been feeling low and thinking about harming myself").to_s)
  end

  test "vague or social chatter does not match the KB" do
    [ "what's going on", "hi there", "ok thanks", "hmm", "what's up" ].each do |q|
      assert_nil Sage::Knowledge.answer(q), "should not match KB: #{q.inspect}"
    end
  end

  test "content_tokens strips stopwords and short tokens" do
    assert_equal %w[improve sleep], Sage::Knowledge.content_tokens("how do I improve my sleep")
  end

  # ── Integration with the grounded engine ───────────────────────────────────
  test "grounded engine answers a real question from the KB with a disclaimer" do
    reply = SageAiService.new.chat("how can I reduce bloating after meals")
    assert_match(/fiber|fermented|gut|digest/i, reply)
    assert_match(/not medical advice/i, reply)
  end

  test "crisis routing wins over any topical match" do
    reply = SageAiService.new.chat("I'm having chest pain and trouble breathing")
    assert_match(/911/, reply)
  end
end
