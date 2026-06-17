module Admin
  # Secure messaging from the care team's side — one thread per member.
  class ConversationsController < BaseController
    def index
      @threads = User.members
                     .left_joins(:messages)
                     .select("users.*, MAX(messages.created_at) AS last_message_at, COUNT(messages.id) AS message_count")
                     .group("users.id")
                     .order(Arel.sql("MAX(messages.created_at) DESC"))
      @unread = Message.unread.where("messages.sender_id = messages.member_id").group(:member_id).count
      @last_bodies = Message.where(id: Message.group(:member_id).select("MAX(id)")).index_by(&:member_id)
    end

    def show
      @member   = User.members.find(params[:id])
      @messages = @member.messages.chronological.includes(:sender)
      @member.messages.unread.where("sender_id = member_id").update_all(read_at: Time.current)
      @message  = Message.new
    end

    def reply
      @member = User.members.find(params[:id])
      message = @member.messages.new(sender: current_user, body: params.dig(:message, :body))
      if message.save
        redirect_to admin_conversation_path(@member)
      else
        redirect_to admin_conversation_path(@member), danger: "Your reply can't be blank."
      end
    end
  end
end
