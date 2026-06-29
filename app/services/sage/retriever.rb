require "zlib"

module Sage
  # Tiny, dependency-free semantic retriever. Embeds short text into a sparse
  # vector via word + bigram + character-trigram *feature hashing* (the "hashing
  # trick"), L2-normalizes it, and ranks documents by cosine similarity.
  #
  # It is not a transformer — there is no model, no download, no API, no native
  # extension. That's the point: it runs instantly on a free-tier dyno and gives
  # the grounded engine genuine "which of these vetted answers is closest to what
  # they asked?" retrieval instead of brittle keyword matching.
  class Retriever
    DIMS = 2048

    # Cosine cutoff for a real hashing-IR match (see Sage::Knowledge::THRESHOLD).
    # Exposed alongside SemanticRetriever#threshold so Knowledge stays backend-agnostic.
    THRESHOLD = 0.16

    def initialize(dims: DIMS)
      @dims = dims
      @docs = [] # [{ ref:, vec: }]
    end

    # Mirrors SemanticRetriever so callers can pick a backend without branching.
    def dense?
      false
    end

    def threshold
      THRESHOLD
    end

    def add(ref, text)
      @docs << { ref: ref, vec: embed(text) }
      self
    end

    # => [[ref, score], ...] sorted by descending cosine similarity.
    def search(query, limit: 3)
      q = embed(query)
      @docs
        .map { |d| [ d[:ref], cosine(q, d[:vec]) ] }
        .sort_by { |(_ref, score)| -score }
        .first(limit)
    end

    # Sparse, L2-normalized embedding as { bucket_index => weight }.
    def embed(text)
      counts = Hash.new(0.0)
      features(text).each { |tok| counts[bucket(tok)] += 1.0 }
      l2_normalize(counts)
    end

    private

    def features(text)
      words = text.to_s.downcase.scan(/[a-z0-9']+/)
      feats = []
      words.each_with_index do |w, i|
        feats << w                              # unigram
        feats << "#{words[i - 1]} #{w}" if i.positive? # bigram → captures phrases
      end
      words.each do |w|                          # char trigrams → typo/morphology robust
        next if w.length < 4
        (0..w.length - 3).each { |j| feats << "#" + w[j, 3] }
      end
      feats
    end

    def bucket(token)
      Zlib.crc32(token) % @dims
    end

    # Both vectors are L2-normalized, so the dot product *is* the cosine.
    def cosine(a, b)
      small, large = a.size <= b.size ? [ a, b ] : [ b, a ]
      small.sum { |k, v| v * (large[k] || 0.0) }
    end

    def l2_normalize(vec)
      norm = Math.sqrt(vec.values.sum { |v| v * v })
      return vec if norm.zero?
      vec.transform_values { |v| v / norm }
    end
  end
end
