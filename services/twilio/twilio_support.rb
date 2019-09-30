module Twilio::TwilioSupport

  delegate :account,                                          to: :twilio_client
  delegate :incoming_phone_numbers, :available_phone_numbers, to: :account

  def twilio_client
    Twilio::REST::Client.new(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
  end

end
