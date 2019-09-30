module Broker

  class OrganizationsController < ApplicationController

    before_action :check_broker_permission
    before_action :load_orgnization
    before_action :load_office, only: %i(remove_office reactivate_office deactivate_office)

    def show
      @office = @organization.offices.build
    end

    def update
      if @organization.update(organization_params)
        flash[:notice] = "Organization details saved successfully!"
        redirect_to broker_organization_path
      else
        @office = @organization.offices.build
        flash[:error] = "Please check your entries..."
        render :show
      end
    end

    def add_office
      @office = @organization.offices.build(office_params)

      if @office.save
        flash[:notice] = "Office created successfully!"
        redirect_to broker_organization_path
      else
        flash[:error] = "Please check your entries..."
        render :show
      end
    end

    def remove_office
      if @office.destroy
        flash[:notice] = "Office deleted successfully!"
        redirect_to broker_organization_path
      end
    end

    def reactivate_office
      flash[:notice] = if @office.reactivate
                         "Office reactiviated successfully!"
                       else
                         "Office was not reactiviated!"
                       end

      redirect_to broker_organization_path
    end

    def deactivate_office
      flash[:notice] = if @office.deactivate
                         "Office deactiviated successfully!"
                       else
                         "Office was not deactiviated!"
                       end

      redirect_to broker_organization_path
    end

    private

    def load_orgnization
      if current_user.broker?
        @organization = ::Organization.includes(:offices).where(broker_id: current_user.id).first
      else
        flash[:warning] = "You don't have permission to see this page!"
        redirect_to edit_profile_path
      end
    end

    def load_office
      @office = @organization.offices.find(params[:office_id])
    end

    def organization_params
      params.require(:organization).permit(
        :brokerage_name, :phone_number, :fax_number,
        :website, :address, :city, :state,
        :zip, :country, :time_zone
      )
    end

    def office_params
      params.require(:office).permit(:name)
    end

  end

end
