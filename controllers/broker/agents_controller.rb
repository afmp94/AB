module Broker

  class AgentsController < ApplicationController

    skip_before_action :authenticate_user!

    before_action :check_broker_permission

    before_action :load_orgnization, except: %i(confirm)
    before_action :load_orgnization_offices, except: %i(confirm)

    def index
      @organization_members = @organization.organization_members
    end

    def new
      @organization_member = @organization.organization_members.build
    end

    def create
      @organization_member = @organization.organization_members.build(organization_member_params)

      if @organization_member.save
        Broker::Organization::NotifyAboutJoiningOrganizationService.new(@organization_member.id).process
        flash[:notice] = "Invited message has sent successfully!"
        redirect_to broker_agents_path
      else
        render :new
      end
    end

    def confirm
      organization_member = OrganizationMember.find_by(token: params[:token], member_id: nil)

      if organization_member.present?
        name = organization_member.organization.brokerage_name
        user = User.find_by(email: organization_member.email_address)

        flash[:notice] = if organization_member.update(member_id: user.id, status: "active")
                           "You are now part of the '#{name}' organization!"
                         else
                           "There was an error!. Please contact support@agentbirght.com"
                         end
      else
        flash[:error] = "Token is no longer valid"
      end

      redirect_to new_user_session_path
    end

    private

    def load_orgnization
      @organization = current_user.organization
    end

    def organization_member_params
      params.require(:organization_member).permit(
        :email_address,
        :office_id
      )
    end

    def load_orgnization_offices
      @organization_offices = @organization.offices

      if @organization_offices.blank?
        flash[:warning] = "Please add office to your organization!"
        redirect_to broker_organization_path
      end
    end

  end

end
