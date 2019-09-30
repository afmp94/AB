class CoachingController < ApplicationController

  def index
    @coaching_cards_service = Cards::CoachingService.new(current_user)
  end

  def cards
    @coaching_messages = current_user.coaching_messages.active
  end

end
