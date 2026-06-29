module Sage
  module Providers
    # Hosted fallback: Groq's free-tier Llama. OPT-IN ONLY — used solely when the
    # operator sets GROQ_API_KEY. When enabled, only minimal derived wellness
    # metrics (never direct identifiers like name+DOB, email, or member ID) are
    # sent off-server; see AiAssistantService#system_prompt_with_context. Returns
    # nil on any failure so the chain falls through to the grounded engine.
    class Groq
      def available?
        Sage::Config.groq_key.present?
      end

      def chat(message, context: {}, history: [])
        return nil unless available?

        AiAssistantService.new.chat_with_history(message, context: context, history: history)
      end
    end
  end
end
