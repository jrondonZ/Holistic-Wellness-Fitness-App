# Member-side secure messaging — their single conversation with the care team.
class MessagesController < ChartController
  def index
    @messages = current_user.messages.chronological.includes(:sender)
    # Mark the care team's messages as read now that the member is viewing them.
    current_user.messages.unread.where.not(sender_id: current_user.id).update_all(read_at: Time.current)
  end

  def create
    message = current_user.messages.new(sender: current_user, body: params.dig(:message, :body))
    if message.save
      redirect_to messages_path
    else
      redirect_to messages_path, danger: "Your message can't be blank."
    end
  end
end
