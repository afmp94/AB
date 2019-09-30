module Coaching

  module Cards

    module TakeActionOnNewLead

      class Creator < BaseMessageCreator

        def process
          collection_to_evaluate.each do |lead|
            user = lead.user || lead.created_by_user

            unless coaching_message_active?(user, card.id, lead)
              print_log_message(user)

              create_coaching_message(user, lead)
            end
          end
        end

        private

        def card_name
          "take_action_on_new_lead"
        end

        def collection_to_evaluate
          Lead.
            lead_status.
            where(
              updated_at: (Time.current - 15.days..Time.current - 3.days),
              contacted_status: [0, 1, 2]
            )
        end

      end

    end

  end

end
