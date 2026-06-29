module Sage
  # Central, env-driven configuration for the Sage wellness assistant.
  #
  # Sage answers through a *chain* of providers, tried in order and always ending
  # in the built-in `grounded` engine — which needs no API key, no model
  # download, and runs fine on a free-tier dyno. Crucially for a health app, the
  # default chain is grounded-only, so **no member data ever leaves the server**
  # unless the operator explicitly opts into a cloud model. The chain auto-detects
  # what the environment is configured for:
  #
  #   • Set LOCAL_LLM_URL (or OLLAMA_URL) to an Ollama / any OpenAI-compatible
  #     server  → your own local model, free, no key, PHI stays on your infra.
  #   • Set GROQ_API_KEY                                          → hosted fallback.
  #   • Nothing set                                              → grounded only.
  #
  # Override the order explicitly with SAGE_PROVIDERS="local_llm,groq,grounded".
  module Config
    DEFAULT_LOCAL_MODEL = "llama3.2".freeze
    KNOWN_PROVIDERS     = %i[local_llm groq grounded].freeze

    module_function

    # Ordered list of provider keys to try. `:grounded` is always appended so a
    # reply is guaranteed even when every networked provider is down/unconfigured.
    def provider_chain
      chain =
        if (explicit = ENV["SAGE_PROVIDERS"]).present?
          explicit.split(",").filter_map { |s| s.strip.downcase.presence&.to_sym }
        else
          auto = []
          auto << :local_llm if local_llm_url.present?
          auto << :groq      if groq_key.present?
          auto
        end
      chain &= KNOWN_PROVIDERS              # drop anything unrecognized
      (chain + [ :grounded ]).uniq          # grounded is the guaranteed floor
    end

    # True when every configured provider runs on infrastructure you control
    # (the built-in grounded engine or a self-hosted local model) — i.e. no
    # member data is sent to a third party. Surfaced so the UI/operator can
    # confirm Sage is running in a PHI-safe, in-house configuration.
    def fully_local?
      provider_chain.all? { |p| %i[local_llm grounded].include?(p) }
    end

    # Base URL of an OpenAI-compatible server, e.g. "http://localhost:11434/v1"
    # (Ollama). Providers append "/chat/completions".
    def local_llm_url
      url = ENV["LOCAL_LLM_URL"].presence || ENV["OLLAMA_URL"].presence
      url && url.strip.chomp("/")
    end

    def local_llm_model
      ENV["LOCAL_LLM_MODEL"].presence || DEFAULT_LOCAL_MODEL
    end

    # Most local servers (Ollama, llama.cpp) need no key; allow one for gateways.
    def local_llm_key
      ENV["LOCAL_LLM_API_KEY"].presence
    end

    def groq_key
      ENV["GROQ_API_KEY"].presence
    end

    def request_timeout
      [ (ENV["SAGE_TIMEOUT"].presence || 20).to_i, 5 ].max
    end
  end
end
