class MessageBroadcastService

  attr_reader :user, :title, :message

  def initialize(user, title)
    @user  = user
    @title = title
  end

  def fetch_message
    return @message if @message.present?

    read_message_broadcast_ids = user.read_message_broadcasts.pluck(:message_broadcast_id)
    @message = MessageBroadcast.where.not(id: read_message_broadcast_ids).find_by(title: title)
  end

end
