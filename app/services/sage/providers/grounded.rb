module Sage
  module Providers
    # The always-available floor: a $0, no-download, in-process engine that
    # answers from the member's live chart context + a vetted wellness knowledge
    # base. Never raises out, never returns blank — this is what guarantees Sage
    # always replies, even on a free-tier dyno with no model configured, and it
    # keeps every word of the conversation on your own server.
    class Grounded
      def available?
        true
      end

      def chat(message, context: {}, history: [])
        SageAiService.new.chat(message, context: context, history: history)
      end
    end
  end
end
