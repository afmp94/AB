class SmsMessagesController < ApplicationController

  def create
    @result = SmsMessages::OutgoingMessagesHandler.call(
      params: outgoing_messages_params,
      user: current_user
    )

    set_appropriate_flash

    redirect_back fallback_location: root_path
  end

  private

  def outgoing_messages_params
    sms_message_params.merge(
      phones: params[:phones],
      image_id: params[:image_id]
    )
  end

  def sms_message_params
    params.require(:sms_message).permit(:body)
  end

  def set_appropriate_flash
    return flash[:error]  = "Your text message was not sent. Please try again." unless @result
    return flash[:notice] = "Your text message was sent."                       if @result.empty?

    flash[:error] = "Your text message to #{@result.join(', ')} could not be sent."
  end

end
