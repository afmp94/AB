class Coaching::CardMessageCreator

  def process
    Rails.logger.info "[COACHING] STARTING Coaching::CardMessageCreator"

    CoachingCard.all.each do |coaching_card|
      Rails.logger.info "[COACHING] Processing #{coaching_card.name}..."

      creator_klass = "Coaching::Cards::#{coaching_card.name.camelize}::Creator"
      creator_klass.constantize.new.process
    end

    Rails.logger.info "[COACHING] Message creation complete.\n"
  end

end
