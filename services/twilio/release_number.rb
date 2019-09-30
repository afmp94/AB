class Twilio::ReleaseNumber < ApplicationService

  include Twilio::TwilioSupport

  delegate :twilio_phone_number, to: :user

  def initialize(user:)
    @user = user
  end

  def call
    # Prevent sample data number from being deleted
    unless twilio_phone_number&.sid == "PN23b4fe12db15687ec8b19bfda23edb6f"
      incoming_phone_numbers.get(twilio_phone_number&.sid).
        delete

      twilio_phone_number&.destroy
    end
  rescue Twilio::REST::RequestError => e
    Rails.logger.info "[TWILIO::ReleaseNumber] Failed."
    Rails.logger.info "[TWILIO::ReleaseNumber] Error: #{e}"
    false
  end

  private

  attr_reader :user

end
