class CoachingMessagesController < ApplicationController

  def update
    @coaching_message = CoachingMessage.find(params[:id])

    case params[:card_action]
    when "snooze"
      @coaching_message.snooze!
    when "cancel"
      @coaching_message.cancel!
    when "dismiss"
      @coaching_message.dismiss!
    end

    redirect_back(fallback_location: coaching_cards_path)
  end

end
