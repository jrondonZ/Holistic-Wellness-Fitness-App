module Sage
  # On-device sentence embeddings via sentence-transformers/all-MiniLM-L6-v2,
  # run in-process through onnxruntime (the `informers` gem). No Python, no API
  # call: the ~80MB ONNX model is downloaded once from Hugging Face and cached on
  # disk, then every embedding is a local forward pass producing a 384-dim,
  # L2-normalized vector. For a health app this matters: semantic search over the
  # wellness knowledge base runs entirely on your own server — no member text is
  # sent anywhere.
  #
  # This is the real-model upgrade to the dependency-free hashing Retriever. It is
  # deliberately *optional at runtime*: when the gem isn't bundled, the weights
  # can't be fetched (no network / restricted egress), the dyno is too small, or
  # SAGE_NEURAL is turned off, `available?` is false and callers transparently
  # fall back to the hashing retriever. Sage keeps answering either way.
  #
  #   Sage::Embeddings.available?              # => true once the model is loaded
  #   Sage::Embeddings.embed("gut healing")    # => [0.013, -0.041, ...] (384)
  module Embeddings
    DEFAULT_MODEL = "sentence-transformers/all-MiniLM-L6-v2".freeze
    DIMS          = 384

    class << self
      # True only when on-device embeddings are usable. The model is loaded lazily
      # on first call and the outcome (success *or* failure) is memoized, so a slow
      # or failed load never repeats on the request hot path.
      def available?
        return false unless enabled?
        load_once
        !@pipeline.nil?
      end

      # => Array<Float> (384-dim, unit length) or nil when unavailable.
      def embed(text)
        return nil unless available?
        vec = @pipeline.call(text.to_s)
        vec.is_a?(Array) ? vec : nil
      rescue StandardError => e
        warn_once(:embed, e)
        nil
      end

      # Batched embedding — one forward pass for the whole list.
      # => Array<Array<Float>> or nil.
      def embed_batch(texts)
        return nil unless available?
        list = Array(texts).map(&:to_s)
        return [] if list.empty?
        out = @pipeline.call(list)
        out.is_a?(Array) ? out : nil
      rescue StandardError => e
        warn_once(:embed_batch, e)
        nil
      end

      def model_id
        ENV["SAGE_EMBED_MODEL"].presence || DEFAULT_MODEL
      end

      # Inject a fake/loaded pipeline (tests) so embedding logic can be exercised
      # without downloading weights.
      def pipeline=(obj)
        @loaded   = true
        @pipeline = obj
      end

      # Reset memoized state so a changed ENV or stub takes effect (tests/boot).
      def reset!
        @loaded   = false
        @pipeline = nil
        @warned   = nil
      end

      private

      # SAGE_NEURAL=off|0|false|no disables every on-device model (embeddings +
      # intent), guaranteeing the zero-dependency engine on constrained hosts.
      def enabled?
        !%w[0 false off no].include?(ENV["SAGE_NEURAL"].to_s.strip.downcase)
      end

      def load_once
        return if @loaded
        mutex.synchronize do
          return if @loaded
          @loaded   = true
          @pipeline = build_pipeline
        end
      end

      def build_pipeline
        require "informers"
        # "embedding" defaults to full precision (best accuracy) and applies mean
        # pooling + L2 normalization, so the raw output is already cosine-ready.
        Informers.pipeline("embedding", model_id)
      rescue LoadError => e
        log(:info, "informers gem unavailable (#{e.message}); using hashing retriever")
        nil
      rescue StandardError => e
        log(:warn, "could not load #{model_id} (#{e.class}: #{e.message}); using hashing retriever")
        nil
      end

      def mutex
        @mutex ||= Mutex.new
      end

      def warn_once(where, err)
        return if @warned
        @warned = true
        log(:warn, "#{where} failed (#{err.class}: #{err.message}); falling back to hashing")
      end

      def log(level, msg)
        Rails.logger.public_send(level, "[Sage::Embeddings] #{msg}") if defined?(Rails) && Rails.logger
      end
    end
  end
end
