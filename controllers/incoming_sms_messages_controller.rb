class IncomingSmsMessagesController < ApplicationController

  skip_before_action :authenticate_user!, only: :create
  skip_before_action :verify_authenticity_token, only: :create

  def create
    Rails.logger.info "[IncomingSmsMessagesController] Create...."
    SmsMessages::IncomingMessagesHandler.new(params: incoming_sms_message_params).call
    render xml: Twilio::TwiML::Response.new.text
  end

  private

  def incoming_sms_message_params
    params.permit(
      :AccountSid,
      :ApiVersion,
      :Body,
      :From,
      :FromCity,
      :FromCountry,
      :FromState,
      :FromZip,
      :MediaContentType0,
      :MediaContentType1,
      :MediaContentType2,
      :MediaContentType3,
      :MediaContentType4,
      :MediaContentType5,
      :MediaContentType6,
      :MediaContentType7,
      :MediaContentType8,
      :MediaContentType9,
      :MediaUrl0,
      :MediaUrl1,
      :MediaUrl2,
      :MediaUrl3,
      :MediaUrl4,
      :MediaUrl5,
      :MediaUrl6,
      :MediaUrl7,
      :MediaUrl8,
      :MediaUrl9,
      :MessageSid,
      :NumMedia,
      :NumSegments,
      :SmsMessageSid,
      :SmsSid,
      :SmsStatus,
      :To,
      :ToCity,
      :ToCountry,
      :ToState,
      :ToZip,
    )
  end

end
