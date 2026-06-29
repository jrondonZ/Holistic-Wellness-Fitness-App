module Sage
  # On-device intent detection via a DistilBERT zero-shot classifier
  # (Xenova/distilbert-base-uncased-mnli) run in-process through onnxruntime (the
  # `informers` gem). No Python, no API call. This is the real-model upgrade to
  # the brittle regex intent matching in SageAiService: instead of keyword
  # patterns, it scores the message against natural-language descriptions of each
  # intent and routes to the best one — so "I keep waking up at 3am exhausted"
  # lands on :sleep without containing the word "sleep".
  #
  # Zero-shot (NLI entailment) is used deliberately: it needs no labeled training
  # data and no fine-tuning, yet runs locally. The int8-quantized model keeps the
  # footprint small (~70MB) for constrained dynos.
  #
  # Like Sage::Embeddings this is optional at runtime: when the gem/model/weights
  # aren't available or SAGE_NEURAL(_INTENT) is off, #classify returns nil and the
  # caller falls back to its rule-based classifier. Crisis/urgent-care messages
  # are always caught by fast deterministic rules upstream — never gated on this
  # model.
  class IntentClassifier
    DEFAULT_MODEL      = "Xenova/distilbert-base-uncased-mnli".freeze
    HYPOTHESIS         = "This message is about {}.".freeze
    DEFAULT_THRESHOLD  = 0.55

    # Natural-language label => Sage intent symbol. Phrasings are written as the
    # *topic* of the message so the entailment model scores them cleanly. :stats
    # and :default are intentionally left to the rule-based layer (they hinge on
    # chart-data references / "none of the above").
    LABELS = {
      "a medical emergency or thoughts of self-harm"            => :emergency,
      "greeting someone or saying hello"                        => :greeting,
      "thanking someone"                                        => :thanks,
      "saying goodbye"                                          => :goodbye,
      "feeling discouraged, unmotivated or like giving up"      => :worried,
      "nutrition, diet, food, calories or what to eat"          => :nutrition,
      "gut health, digestion, bloating or the microbiome"       => :gut,
      "exercise, workouts, training or building strength"       => :fitness,
      "sleep, rest or feeling tired"                            => :sleep,
      "stress, anxiety, burnout or mindfulness"                 => :stress,
      "drinking water or staying hydrated"                      => :hydration,
      "body weight, BMI or weight-loss goals"                   => :weight,
      "blood pressure, heart rate or vital signs"               => :vitals,
      "building a habit, a streak or staying consistent"        => :habit,
      "asking for general wellness or health tips"              => :tips
    }.freeze
    CANDIDATES = LABELS.keys.freeze

    class << self
      # => intent Symbol, or nil when the model is unavailable / not confident.
      def classify(message)
        instance.classify(message)
      end

      def available?
        instance.available?
      end

      def instance
        @instance ||= new
      end

      # Inject a fake classifier pipeline (tests).
      def pipeline=(obj)
        instance.pipeline = obj
      end

      def reset!
        @instance = nil
      end
    end

    def initialize
      @cache  = {}
      @loaded = false
    end

    def available?
      return false unless enabled?
      load_once
      !@pipeline.nil?
    end

    # Score the message against every candidate intent and return the best one
    # when it clears the confidence threshold; otherwise nil so the caller's
    # rule-based classifier takes over.
    def classify(message)
      msg = message.to_s.strip
      return nil if msg.empty? || !available?

      key = msg.downcase
      return @cache[key] if @cache.key?(key)

      res        = @pipeline.call(msg, CANDIDATES, hypothesis_template: HYPOTHESIS, multi_label: false)
      labels     = res[:labels] || res["labels"] || []
      scores     = res[:scores] || res["scores"] || []
      top_label  = labels.first
      top_score  = scores.first.to_f
      intent     = (top_score >= threshold) ? LABELS[top_label] : nil

      remember(key, intent)
      intent
    rescue StandardError => e
      log(:warn, "classify failed (#{e.class}: #{e.message}); falling back to rules")
      nil
    end

    def pipeline=(obj)
      @loaded   = true
      @pipeline = obj
    end

    private

    def threshold
      (ENV["SAGE_INTENT_THRESHOLD"].presence || DEFAULT_THRESHOLD).to_f
    end

    # Disabled by SAGE_NEURAL=off (kills all on-device models) or, independently,
    # SAGE_NEURAL_INTENT=off (keeps embeddings but drops the heavier classifier —
    # useful on a small dyno that can host one model but not two).
    def enabled?
      off = %w[0 false off no]
      !off.include?(ENV["SAGE_NEURAL"].to_s.strip.downcase) &&
        !off.include?(ENV["SAGE_NEURAL_INTENT"].to_s.strip.downcase)
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
      # int8-quantized DistilBERT-MNLI keeps memory low; intent routing is coarse
      # enough that quantization costs no meaningful accuracy.
      Informers.pipeline("zero-shot-classification", model_id, quantized: true)
    rescue LoadError => e
      log(:info, "informers gem unavailable (#{e.message}); using rule-based intents")
      nil
    rescue StandardError => e
      log(:warn, "could not load #{model_id} (#{e.class}: #{e.message}); using rule-based intents")
      nil
    end

    def model_id
      ENV["SAGE_INTENT_MODEL"].presence || DEFAULT_MODEL
    end

    # Bounded result cache so repeated/identical prompts skip the forward pass
    # without letting memory grow unbounded.
    def remember(key, intent)
      @cache.shift if @cache.size >= 512
      @cache[key] = intent
    end

    def mutex
      @mutex ||= Mutex.new
    end

    def log(level, msg)
      Rails.logger.public_send(level, "[Sage::IntentClassifier] #{msg}") if defined?(Rails) && Rails.logger
    end
  end
end
