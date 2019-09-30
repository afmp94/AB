class UserSettings::PhoneNumberUrlsController < ApplicationController

  def index
    @phone_number_properties = Twilio::UpdateNumber.new(
      twilio_phone_number: current_user.twilio_phone_number
    ).show
  end

  def create
    @result = Twilio::UpdateNumber.call(
      twilio_phone_number: current_user.twilio_phone_number,
      voice_url: constructed_voice_url,
      sms_url: constructed_sms_url
    )
  end

  private

  def urls_params
    params.permit(:custom_url)
  end

  def constructed_voice_url
    if params[:custom_url].present?
      "#{params[:custom_url]}/calls"
    else
      calls_url
    end
  end

  def constructed_sms_url
    if params[:custom_url].present?
      "#{params[:custom_url]}/incoming_sms_messages"
    else
      incoming_sms_messages_url
    end
  end

end
