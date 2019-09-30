module Broker

  module Organization

    class NotifyAboutJoiningOrganizationService

      attr_reader :organization_member_id

      def initialize(organization_member_id)
        @organization_member_id = organization_member_id
      end

      def process
        @organization_member = OrganizationMember.find @organization_member_id

        if @organization_member.existing_user?
          send_confimrmation
        else
          send_invitation
        end
      end

      private

      def send_confimrmation
        BrokerMailer.confirm_user_to_join_organization(@organization_member).deliver
      end

      def send_invitation
        BrokerMailer.invite_user_to_join_organization(@organization_member).deliver
      end

    end

  end

end
