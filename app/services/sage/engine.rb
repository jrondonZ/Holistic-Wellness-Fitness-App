module Sage
  # Orchestrates the Sage provider chain. Tries each configured provider in order
  # and returns the first non-blank reply; if a provider is unavailable, errors
  # out, or returns blank, it falls through to the next. The chain always ends in
  # `grounded`, so `reply` is guaranteed to return usable text and never raises —
  # Sage always answers.
  #
  #   Sage::Engine.new.reply("what should I eat after a workout?", context:, history:)
  #   # => #<Result text: "...", provider: :grounded>
  class Engine
    Result = Struct.new(:text, :provider, keyword_init: true)

    PROVIDERS = {
      local_llm: Providers::LocalLlm,
      groq:      Providers::Groq,
      grounded:  Providers::Grounded
    }.freeze

    def reply(message, context: {}, history: [])
      Sage::Config.provider_chain.each do |name|
        klass = PROVIDERS[name]
        next unless klass

        provider = klass.new
        next unless safe_available?(provider, name)

        text = safe_chat(provider, name, message, context, history)
        return Result.new(text: text.to_s.strip, provider: name) if text.present?
      end

      # Belt-and-suspenders: the chain already includes :grounded, but if a
      # custom SAGE_PROVIDERS omitted it, still guarantee an answer.
      Result.new(
        text:     Providers::Grounded.new.chat(message, context: context, history: history),
        provider: :grounded
      )
    end

    private

    def safe_available?(provider, name)
      provider.available?
    rescue StandardError => e
      Rails.logger.warn("[Sage] #{name}#available? raised: #{e.message}")
      false
    end

    def safe_chat(provider, name, message, context, history)
      provider.chat(message, context: context, history: history)
    rescue StandardError => e
      Rails.logger.warn("[Sage] #{name}#chat raised: #{e.message}")
      nil
    end
  end
end
