require "uri"

module Sage
  module Providers
    # Your own model — free, key-less, and PHI-safe. Talks the OpenAI
    # chat-completions format to any local/self-hosted server (Ollama, llama.cpp,
    # vLLM, LM Studio, LiteLLM …). Enabled by setting LOCAL_LLM_URL / OLLAMA_URL.
    #
    # Because the endpoint runs on infrastructure you control, member data never
    # leaves your environment. Reuses AiAssistantService (same Sage system prompt
    # + context + history handling) pointed at the local endpoint, so
    # quality/voice stay consistent across providers.
    class LocalLlm
      def available?
        Sage::Config.local_llm_url.present?
      end

      def chat(message, context: {}, history: [])
        return nil unless available?

        AiAssistantService.new(
          endpoint: URI("#{Sage::Config.local_llm_url}/chat/completions"),
          model:    Sage::Config.local_llm_model,
          api_key:  Sage::Config.local_llm_key,
          timeout:  Sage::Config.request_timeout
        ).chat_with_history(message, context: context, history: history)
      end
    end
  end
end
