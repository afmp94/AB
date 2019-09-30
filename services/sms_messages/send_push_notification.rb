class SmsMessages::SendPushNotification < Firebase::BasePushNotifier

  delegate :body, :contact, to: :model, allow_nil: true

  private

  def title
    contact&.name || "Unknown Contact"
  end

  def additional_info
    { contact_id: contact&.id }
  end

end
