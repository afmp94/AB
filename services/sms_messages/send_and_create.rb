class SmsMessages::SendAndCreate < ApplicationService

  def initialize(user:, phone_number:, body:, image:)
    @user = user
    @body = body
    @phone_number = phone_number
    @image = image
  end

  def call
    return unless send_message

    user.sms_messages.create(
      sid: send_message.sid,
      body: body,
      to: phone_number,
      from: twilio_number,
      contact: contact,
      image: image
    )
  end

  private

  attr_reader :user, :phone_number, :body, :image

  # rubocop:disable Style/AccessModifierDeclarations
  private *delegate(:twilio_phone_number, to: :user, prefix: true)
  private *delegate(:twilio_number,       to: :user_twilio_phone_number)
  # rubocop:enable Style/AccessModifierDeclarations

  def send_message
    @send_message ||= Twilio::SmsSender.call(
      from: user,
      to: phone_number,
      body: body,
      media_url: image&.file_url,
    )
  end

  def contact
    user.contact_phone_numbers.find_by(number: phone_number)&.owner
  end

end
