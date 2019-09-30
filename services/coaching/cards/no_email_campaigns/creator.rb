module Coaching

  module Cards

    module NoEmailCampaigns

      class Creator < BaseMessageCreator

        def process
          collection_to_evaluate.each do |user|
            unless coaching_message_exists?(user, card.id)
              print_log_message(user)

              create_coaching_message(user)
            end
          end
        end

        private

        def card_name
          "no_email_campaigns"
        end

        def collection_to_evaluate
          User.left_outer_joins(:email_campaigns).where(email_campaigns: { id: nil })
        end

      end

    end

  end

end
