require "test_helper"

# Covers the DistilBERT zero-shot intent classifier and its integration with
# SageAiService. A fake pipeline (matching informers' { labels:, scores: } shape)
# lets us drive routing deterministically without a model download.
class SageIntentClassifierTest < ActiveSupport::TestCase
  # Scores each candidate label via the given block, then returns them sorted by
  # score descending — exactly the contract IntentClassifier consumes.
  class FakeZeroShot
    def initialize(&scorer)
      @scorer = scorer
    end

    def call(text, candidate_labels, hypothesis_template: nil, multi_label: false)
      scored = candidate_labels.map { |l| [ l, @scorer.call(text, l).to_f ] }.sort_by { |(_l, s)| -s }
      { sequence: text, labels: scored.map(&:first), scores: scored.map(&:last) }
    end
  end

  def with_neural_on
    saved_n = ENV["SAGE_NEURAL"]
    saved_i = ENV["SAGE_NEURAL_INTENT"]
    ENV["SAGE_NEURAL"] = "on"
    ENV.delete("SAGE_NEURAL_INTENT")
    Sage::IntentClassifier.reset!
    yield
  ensure
    saved_n.nil? ? ENV.delete("SAGE_NEURAL") : (ENV["SAGE_NEURAL"] = saved_n)
    saved_i.nil? ? ENV.delete("SAGE_NEURAL_INTENT") : (ENV["SAGE_NEURAL_INTENT"] = saved_i)
    Sage::IntentClassifier.reset!
  end

  test "intent classifier is disabled by default in tests" do
    Sage::IntentClassifier.reset!
    refute Sage::IntentClassifier.available?
    assert_nil Sage::IntentClassifier.classify("how do I sleep better")
  end

  test "maps the top entailed label to its intent above threshold" do
    with_neural_on do
      Sage::IntentClassifier.pipeline = FakeZeroShot.new do |_text, label|
        label.include?("sleep") ? 0.92 : 0.02
      end
      assert Sage::IntentClassifier.available?
      assert_equal :sleep, Sage::IntentClassifier.classify("I keep tossing and turning all night")
    end
  end

  test "defers to rules (returns nil) when no label clears the threshold" do
    with_neural_on do
      Sage::IntentClassifier.pipeline = FakeZeroShot.new { |_t, _l| 0.2 }
      assert_nil Sage::IntentClassifier.classify("hmm, not sure what i mean")
    end
  end

  test "SAGE_NEURAL_INTENT=off disables the classifier independently" do
    with_neural_on do
      ENV["SAGE_NEURAL_INTENT"] = "off"
      Sage::IntentClassifier.reset!
      Sage::IntentClassifier.pipeline = FakeZeroShot.new { |_t, _l| 0.99 }
      refute Sage::IntentClassifier.available?
      assert_nil Sage::IntentClassifier.classify("anything at all")
    end
  end

  # ── Integration with the grounded engine ───────────────────────────────────
  # Routes to a non-knowledge-base intent (:habit) so the test never reaches the
  # embedding model — it stays fully offline and deterministic.
  test "SageAiService routes through the neural classifier when confident" do
    with_neural_on do
      Sage::IntentClassifier.pipeline = FakeZeroShot.new do |_text, label|
        label.include?("habit") ? 0.9 : 0.01
      end
      reply = SageAiService.new.chat("how do I stop quitting on myself every few weeks")
      assert_match(/habit|streak|chain|consistent/i, reply)
    end
  end

  test "crisis messages are caught by rules before the classifier ever runs" do
    with_neural_on do
      # Even a classifier that loves 'tips' can't override an emergency.
      Sage::IntentClassifier.pipeline = FakeZeroShot.new do |_t, label|
        label.include?("tips") ? 0.99 : 0.0
      end
      reply = SageAiService.new.chat("I think I'm having a heart attack")
      assert_match(/911/, reply)
    end
  end
end
