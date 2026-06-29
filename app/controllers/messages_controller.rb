# Member-side secure messaging — one thread per provider the member can message.
class MessagesController < ChartController
  before_action :set_provider, only: [ :show, :create ]

  def index
    @providers = current_user.messageable_providers
    msgs = current_user.messages.includes(:provider, :sender).to_a
    @threads = @providers.map do |provider|
      thread = msgs.select { |m| m.provider_id == provider.id }
      { provider: provider,
        last: thread.max_by(&:created_at),
        unread: thread.count { |m| m.read_at.nil? && m.sender_id != current_user.id } }
    end.sort_by { |t| t[:last]&.created_at || Time.at(0) }.reverse
  end

  def show
    thread = Message.thread(current_user, @provider)
    @messages = thread.chronological.includes(:sender)
    thread.unread.where.not(sender_id: current_user.id).update_all(read_at: Time.current)
    @topics = Message::TOPICS

    # PHI access trail: the member opened a secure message thread with a provider.
    audit!(:view, resource: @provider, metadata: { area: "messages", provider_id: @provider.id })
  end

  def create
    message = current_user.messages.new(
      provider: @provider, sender: current_user,
      body: params.dig(:message, :body), topic: params.dig(:message, :topic)
    )
    if message.save
      Notification.notify(@provider, kind: "message", icon: "fa-comments",
                          title: "New message from #{current_user.full_name}",
                          body: message.topic.presence, url: admin_conversation_path(current_user))
      redirect_to message_thread_path(@provider)
    else
      redirect_to message_thread_path(@provider), danger: "Your message can't be blank."
    end
  end

  private

  def set_provider
    @provider = User.staff.find(params[:provider_id])
    # If the member has assigned providers, restrict messaging to those.
    return unless current_user.providers.exists?
    return if current_user.providers.exists?(id: @provider.id)

    redirect_to messages_path, danger: "You can only message a provider assigned to your care."
  end
end
