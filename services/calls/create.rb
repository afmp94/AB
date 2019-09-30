class Calls::Create < ApplicationService

  CALLER_ID       = "AgentBright".freeze
  FAILURE_MESSAGE = "Sorry, called number is invalid".freeze

  delegate :user,          to: :twilio_phone_number, allow_nil: true
  delegate :mobile_number, to: :user,                allow_nil: true

  def initialize(called_number:)
    @called_number = called_number
  end

  def call
    valid_call_target? ? success_response : failure_response
  end

  private

  attr_reader :called_number

  def valid_call_target?
    mobile_number.present?
  end

  def twilio_phone_number
    @twilio_phone_number ||= TwilioPhoneNumber.find_by(twilio_number: called_number)
  end

  def success_response
    Twilio::TwiML::Response.new do |r|
      r.Dial(callerId: caller_id) do |d|
        d.Number(mobile_number)
      end
    end
  end

  def failure_response
    Twilio::TwiML::Response.new do |r|
      r.Say(FAILURE_MESSAGE, voice: :woman)
    end
  end

  def caller_id
    CALLER_ID
  end

end
