module Coaching

  class BaseMessageCreator

    attr_accessor :card

    def initialize
      @card = CoachingCard.find_by(name: card_name)
    end

    private

    def card_name
      # hook for subclasses
    end

    def print_log_message(user)
      Rails.logger.info "[COACHING]   creating new #{card_name} message for #{user.name}..."
    end

    def create_coaching_message(user, messageable=nil)
      user.coaching_messages.create!(
        coaching_card_id: card.id,
        messageable: messageable
      )
    end

    def coaching_message_exists?(user, card_id, messageable=nil)
      user.coaching_messages.where(
        coaching_card_id: card_id,
        messageable: messageable
      ).exists?
    end

    def coaching_message_active?(user, card_id, messageable=nil)
      user.coaching_messages.where(
        coaching_card_id: card_id,
        messageable: messageable,
        completed_at: nil
      ).exists?
    end

  end

end
