class SmsMessages::BroadcastMessage < ApplicationService

  delegate :user, :contact, to: :message, allow_nil: true

  delegate :recent_activities, to: :contact, allow_nil: true

  def initialize(message:)
    @message = message
  end

  def call
    return if recent_activities.blank?

    ActionCable.server.broadcast(
      "incoming_sms_channel_#{user.id}",
      sms_html: message_partial,
      activity_html: activity_partial,
      contact_id: contact.id,
      activity_date: activity.created_at.strftime("%A, %B %-d")
    )
  end

  private

  attr_reader :message

  def message_partial
    ApplicationController.render(
      partial: "sms_messages/contact_sms_message",
      locals: { sms_message: message }
    )
  end

  def activity_partial
    ApplicationController.render(
      partial: "public_activity/sms_message/create",
      locals: { activity: activity, current_user: user }
    )
  end

  def activity
    @activity ||= recent_activities.first
  end

end
