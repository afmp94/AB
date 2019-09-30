class UserSettings::PhoneNumberSettingsController < ApplicationController

  def edit
    @twilio_phone_number = current_user.twilio_phone_number
    @text_message_templates = TextMessageTemplate.
                                owned_and_shared_with(
                                  current_user.team_member_ids_except_self,
                                  current_user.id
                                )
  end

  def update
    @result = Twilio::PurchaseNumber.call(
      user: current_user,
      number: settings_params[:phone_number],
      voice_url: calls_url,
      sms_url: incoming_sms_messages_url
    )
    redirect_to edit_user_settings_phone_number_settings_path, result_notice
  end

  def destroy
    @result = Twilio::ReleaseNumber.call(user: current_user)

    redirect_to edit_user_settings_phone_number_settings_path, result_notice
  end

  private

  def settings_params
    params.permit(:phone_number)
  end

  def result_notice
    @result ? success_notice : failure_notice
  end

  def success_notice
    { notice: I18n.t("profiles.update.done") }
  end

  def failure_notice
    { danger: I18n.t("profiles.update.error") }
  end

end
