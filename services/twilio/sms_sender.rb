class Twilio::SmsSender < ApplicationService

  include Twilio::TwilioSupport

  delegate :account, to: :twilio_client
  delegate :messages, to: :account

  def initialize(from:, to:, body:, media_url:)
    @from = from
    @to = to
    @body = body
    @media_url = media_url
  end

  def call
    messages.create(outgoing_message_params)
  end

  private

  attr_reader :from, :to, :body, :media_url

  # rubocop:disable Style/AccessModifierDeclarations
  private *delegate(:twilio_phone_number, to: :from, prefix: true)
  private *delegate(:twilio_number,       to: :from_twilio_phone_number)
  # rubocop:enable Style/AccessModifierDeclarations

  def outgoing_message_params
    {
      from: twilio_number,
      to: to,
      body: body,
      media_url: media_url
    }.compact
  end

end
