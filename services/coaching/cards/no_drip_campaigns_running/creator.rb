module Coaching

  module Cards

    module NoDripCampaignsRunning

      class Creator < BaseMessageCreator

        def process
          collection_to_evaluate.each do |user|
            unless coaching_message_active?(user, card.id)
              print_log_message(user)

              create_coaching_message(user)
            end
          end
        end

        private

        def card_name
          "no_drip_campaigns_running"
        end

        def collection_to_evaluate
          User.
            left_outer_joins(:action_plans).
            where.not(id: ActionPlan.has_active_memberships.select(:user_id))
        end

      end

    end

  end

end
