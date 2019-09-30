module Coaching

  module Cards

    module AskForTestimonial

      class Creator < BaseMessageCreator

        def process
          collection_to_evaluate.each do |lead|
            user = lead.user

            unless coaching_message_exists?(user, card.id, lead)
              print_log_message(user)

              create_coaching_message(user, lead)
            end
          end
        end

        private

        def card_name
          "ask_for_testimonial"
        end

        def collection_to_evaluate
          Lead.closed_leads_after_date(Time.current - 7.days)
        end

      end

    end

  end

end
