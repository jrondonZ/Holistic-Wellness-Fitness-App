# Optionally warm Sage's on-device models (all-MiniLM-L6-v2 embeddings +
# DistilBERT zero-shot intents) at boot, off the request path, so the first chat
# isn't blocked by the one-time model download/load. Disabled by default because
# loading weights during boot adds memory pressure that a tiny (e.g. free-tier)
# dyno may not have headroom for — there the models load lazily on first use
# instead. Opt in with SAGE_WARMUP=1 on hosts with room to spare.
#
# Safe by construction: runs in a detached thread, swallows all errors, and never
# affects boot success. When neural models are off/unavailable it simply no-ops
# and Sage keeps using the hashing retriever + rule-based intents.
warmup_on  = ActiveModel::Type::Boolean.new.cast(ENV["SAGE_WARMUP"])
neural_off = %w[0 false off no].include?(ENV["SAGE_NEURAL"].to_s.strip.downcase)

if warmup_on && !neural_off && !Rails.env.test?
  Rails.application.config.after_initialize do
    Thread.new do
      Thread.current.report_on_exception = false
      begin
        Sage::Embeddings.available?   # triggers the lazy load/download
        Sage::Knowledge.reset!        # rebuild the KB index on the real model
        Sage::Knowledge.retriever
        Sage::IntentClassifier.available?
        Rails.logger.info("[Sage] model warmup complete " \
          "(embeddings=#{Sage::Embeddings.available?}, intent=#{Sage::IntentClassifier.available?})")
      rescue StandardError => e
        Rails.logger.warn("[Sage] model warmup skipped: #{e.class}: #{e.message}")
      end
    end
  end
end
