module Sage
  # Dense semantic retriever backed by a real embedding model (Sage::Embeddings
  # → all-MiniLM-L6-v2). Drop-in API-compatible with the hashing Sage::Retriever
  # (#add / #search / #embed) so Sage::Knowledge can use either interchangeably.
  #
  # Documents are embedded into 384-dim unit vectors; because the embeddings are
  # already L2-normalized, cosine similarity is a plain dot product. Real
  # contextual embeddings make retrieval markedly more accurate than the
  # word/character feature-hashing fallback ("bloated after meals" ≈ "my
  # digestion is off" even with no shared tokens).
  class SemanticRetriever
    # Minimum cosine for a query to count as a topical hit. Dense MiniLM scores
    # related wellness text well above this and unrelated chatter well below it.
    THRESHOLD = 0.30

    def initialize(embedder: Sage::Embeddings)
      @embedder = embedder
      @docs     = []  # [{ ref:, vec: }]
      @pending  = []  # [[ref, text], ...] embedded in one batch on first search
    end

    def add(ref, text)
      @pending << [ ref, text.to_s ]
      self
    end

    # => [[ref, score], ...] sorted by descending cosine similarity.
    def search(query, limit: 3)
      flush
      q = @embedder.embed(query)
      return [] if q.nil?
      @docs
        .map { |d| [ d[:ref], dot(q, d[:vec]) ] }
        .sort_by { |(_ref, score)| -score }
        .first(limit)
    end

    def embed(text)
      @embedder.embed(text)
    end

    def dense?
      true
    end

    def threshold
      THRESHOLD
    end

    private

    # Embed any not-yet-indexed documents in a single batched forward pass.
    def flush
      return if @pending.empty?
      refs  = @pending.map(&:first)
      texts = @pending.map(&:last)
      vecs  = @embedder.embed_batch(texts) || texts.map { |t| @embedder.embed(t) }
      refs.each_with_index do |ref, i|
        v = vecs[i]
        @docs << { ref: ref, vec: v } if v.is_a?(Array)
      end
      @pending = []
    end

    # Dot product of two equal-length unit vectors == cosine similarity.
    def dot(a, b)
      n = a.size < b.size ? a.size : b.size
      sum = 0.0
      i = 0
      while i < n
        sum += a[i] * b[i]
        i += 1
      end
      sum
    end
  end
end
