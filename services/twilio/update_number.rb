class Twilio::UpdateNumber < ApplicationService

  include Twilio::TwilioSupport

  delegate :sid, to: :twilio_phone_number

  def initialize(twilio_phone_number:, voice_url: nil, sms_url: nil)
    @twilio_phone_number = twilio_phone_number
    @voice_url = voice_url
    @sms_url = sms_url
  end

  def call
    incoming_phone_numbers.get(sid).
      update(
        sms_url: @sms_url,
        voice_url: @voice_url
      )
  rescue Twilio::REST::RequestError => e
    Rails.logger.info "[TWILIO::UPDATE_NUMBER] Failed."
    Rails.logger.info "[TWILIO::UPDATE_NUMBER] Error: #{e}"
    false
  end

  def show
    incoming_phone_numbers.get(sid)
  rescue Twilio::REST::RequestError => e
    Rails.logger.info "[TWILIO::UPDATE_NUMBER] Failed."
    Rails.logger.info "[TWILIO::UPDATE_NUMBER] Error: #{e}"
  end

  private

  attr_reader :twilio_phone_number, :voice_url, :sms_url

end
