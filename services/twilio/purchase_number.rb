class Twilio::PurchaseNumber < ApplicationService

  POST = "POST".freeze

  include Twilio::TwilioSupport

  delegate :update, to: :twilio_phone_number

  def initialize(user:, number:, voice_url:, sms_url:)
    @user   = user
    @number = number
    @voice_url = voice_url
    @sms_url = sms_url
  end

  def call
    purchased_number
    release_previous_number
    update(update_attributes)
  rescue Exception
  end

  private

  attr_reader :user, :number, :voice_url, :sms_url

  def purchased_number
    @purchased_number ||= incoming_phone_numbers.create(number_attributes)
  end

  def release_previous_number
    Twilio::ReleaseNumber.call(user: user)
  end

  def twilio_phone_number
    @twilio_phone_number ||= TwilioPhoneNumber.find_or_initialize_by(user: user)
  end

  def number_attributes
    {
      phone_number: number,
      voice_url: voice_url,
      voice_method: POST,
      sms_url: sms_url,
      sms_method: POST
    }
  end

  def update_attributes
    {
      twilio_number: purchased_number.phone_number,
      sid: purchased_number.sid
    }
  end

end
