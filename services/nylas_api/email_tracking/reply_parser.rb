class NylasApi::EmailTracking::ReplyParser

  attr_accessor :delta, :message_id, :email_message

  def initialize(delta)
    @delta = delta
    @message_id = delta.metadata[:message_id]
    @email_message = EmailMessage.find_by(message_id: message_id)
  end

  def process
    if email_message
      email_message.email_tracking_notifications.create!(notification_params)
    else
      EmailTrackingNotification.create!(notification_params)
    end
    Rails.logger.info "[EmailTrackingNotification] for thread.replied created."
  end

  def notification_params
    {
      nylas_message_id: message_id,
      account_id: delta.account_id,
      notification_type: "thread.replied",
      metadata_id: delta.id,
      notification_at: Time.at(delta.date),
      from_self: delta.metadata[:from_self],
      thread_id: delta.metadata[:thread_id],
      reply_to_message_id: delta.metadata[:reply_to_message_id]
    }
  end

end
