require "test_helper"

# Covers the on-device embedding upgrade: the Sage::Embeddings wrapper, the dense
# SemanticRetriever, and Knowledge picking the right backend. A tiny injected
# fake stands in for the all-MiniLM-L6-v2 ONNX pipeline so the dense logic is
# exercised deterministically without downloading or running a model.
class SageEmbeddingsTest < ActiveSupport::TestCase
  SLEEP = [ 1.0, 0.0, 0.0 ].freeze
  FOOD  = [ 0.0, 1.0, 0.0 ].freeze
  # Substrings → unit vectors. Anything unmatched maps to a third orthogonal axis.
  TABLE = {
    "sleep" => SLEEP, "rest" => SLEEP, "tired" => SLEEP, "bed" => SLEEP,
    "protein" => FOOD, "eat" => FOOD, "meal" => FOOD
  }.freeze

  # Mimics informers' EmbeddingPipeline: callable with a String or an Array.
  FakePipeline = Struct.new(:table) do
    def call(input)
      input.is_a?(Array) ? input.map { |t| vec(t) } : vec(input)
    end

    def vec(text)
      t = text.to_s.downcase
      table.each { |needle, v| return v.dup if t.include?(needle) }
      [ 0.0, 0.0, 1.0 ]
    end
  end

  def fake_embedder
    fp = FakePipeline.new(TABLE)
    emb = Object.new
    emb.define_singleton_method(:embed) { |t| fp.vec(t) }
    emb.define_singleton_method(:embed_batch) { |ts| ts.map { |t| fp.vec(t) } }
    emb
  end

  def with_neural_on
    saved = ENV["SAGE_NEURAL"]
    ENV["SAGE_NEURAL"] = "on"
    Sage::Embeddings.reset!
    yield
  ensure
    saved.nil? ? ENV.delete("SAGE_NEURAL") : (ENV["SAGE_NEURAL"] = saved)
    Sage::Embeddings.reset!
    Sage::Knowledge.reset!
  end

  # ── Wrapper ────────────────────────────────────────────────────────────────
  test "neural embeddings are disabled by default in tests (SAGE_NEURAL=off)" do
    Sage::Embeddings.reset!
    refute Sage::Embeddings.available?
    assert_nil Sage::Embeddings.embed("anything"), "must not reach for a model when disabled"
  end

  test "wrapper delegates to the injected pipeline when enabled" do
    with_neural_on do
      Sage::Embeddings.pipeline = FakePipeline.new(TABLE)
      assert Sage::Embeddings.available?
      assert_equal SLEEP, Sage::Embeddings.embed("I can't sleep at night")
      assert_equal [ SLEEP, FOOD ], Sage::Embeddings.embed_batch([ "need rest", "more protein" ])
    end
  end

  # ── Dense retriever ──────────────────────────────────────────────────────────
  test "SemanticRetriever ranks the closest document via dense cosine" do
    r = Sage::SemanticRetriever.new(embedder: fake_embedder)
    r.add(:sleep, "sleep rest bedtime wind down")
    r.add(:food,  "protein eat meal macros")

    top = r.search("how do I get better sleep", limit: 1).first
    assert_equal :sleep, top[0]
    assert top[1] > 0.9, "expected near-1 cosine for the matching doc"
    assert r.dense?
    assert_in_delta 0.30, r.threshold, 0.001
  end

  test "SemanticRetriever returns nothing when the embedder is unavailable" do
    dead = Object.new
    dead.define_singleton_method(:embed) { |_| nil }
    dead.define_singleton_method(:embed_batch) { |_| nil }
    r = Sage::SemanticRetriever.new(embedder: dead)
    r.add(:a, "anything")
    assert_equal [], r.search("query")
  end

  # ── Knowledge backend selection ──────────────────────────────────────────────
  test "Knowledge uses the dense semantic retriever when embeddings are available" do
    with_neural_on do
      Sage::Embeddings.pipeline = FakePipeline.new(TABLE)
      Sage::Knowledge.reset!
      assert Sage::Knowledge.retriever.dense?, "expected the dense semantic retriever"
      assert_in_delta 0.30, Sage::Knowledge.retriever.threshold, 0.001
    end
  end

  test "Knowledge falls back to the hashing retriever when embeddings are off" do
    Sage::Embeddings.reset!
    Sage::Knowledge.reset!
    refute Sage::Knowledge.retriever.dense?
    assert_in_delta 0.16, Sage::Knowledge.retriever.threshold, 0.001
  ensure
    Sage::Knowledge.reset!
  end
end
