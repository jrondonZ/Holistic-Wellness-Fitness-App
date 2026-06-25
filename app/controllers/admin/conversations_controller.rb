module Admin
  # Care-team messaging — each provider handles their own member conversations.
  class ConversationsController < BaseController
    def index
      messaged_ids = Message.where(provider_id: current_user.id).distinct.pluck(:member_id)
      assigned_ids = current_user.assigned_members.pluck(:id)
      ids = (messaged_ids + assigned_ids).uniq
      @members = User.where(id: ids).order(:first_name, :last_name)

      thread_msgs = Message.where(provider_id: current_user.id, member_id: ids)
      @unread = thread_msgs.unread.where("messages.sender_id = messages.member_id").group(:member_id).count
      @last   = thread_msgs.where(id: thread_msgs.group(:member_id).select("MAX(id)")).index_by(&:member_id)
    end

    def show
      @member   = User.members.find(params[:id])
      thread    = Message.thread(@member, current_user)
      @messages = thread.chronological.includes(:sender)
      thread.unread.where("sender_id = member_id").update_all(read_at: Time.current)
      @message  = Message.new
      @topics   = Message::TOPICS
    end

    def reply
      @member = User.members.find(params[:id])
      message = Message.new(member: @member, provider: current_user, sender: current_user,
                            body: params.dig(:message, :body), topic: params.dig(:message, :topic))
      if message.save
        Notification.notify(@member, kind: "message", icon: "fa-comments",
                            title: "New message from #{current_user.first_name} (care team)",
                            body: message.topic.presence, url: message_thread_path(current_user))
        redirect_to admin_conversation_path(@member)
      else
        redirect_to admin_conversation_path(@member), danger: "Your reply can't be blank."
      end
    end
  end
end
