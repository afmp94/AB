class CoachingMessageActionsController < ApplicationController

  def new
    @coaching_message = CoachingMessage.find(params[:coaching_message_id])

    @coaching_message.complete!

    if @coaching_message.action_path
      resource = @coaching_message.messageable # rubocop:disable Lint/UselessAssignment
      redirect_to eval(@coaching_message.action_path) # rubocop:disable Security/Eval
    else
      redirect_to coaching_cards_path
    end
  end

end
