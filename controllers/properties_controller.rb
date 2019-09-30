class PropertiesController < ApplicationController

  before_action :set_lead, only: [
    :create,
    :create_property_from_modal,
    :destroy,
    :new,
    :refresh_image,
    :update
  ]
  before_action :set_property, only: [
    :destroy,
    :edit,
    :refresh_image,
    :set_level_of_interest,
    :update,
  ]

  def new
    @property = @lead.properties.new
    @property.transaction_type = "Buyer"
    @property.level_of_interest = "Interested"
    @property.build_address
  end

  def create
    @property = @lead.properties.new(property_params)
    @property.address.owner = @property
    respond_to do |format|
      if @property.save
        format.html { redirect_to @lead, notice: "Property added successfully!" }
        format.js unless forced_form_for_mobile_app?
      else
        format.html do
          flash[:danger] = handle_error_message
          render :new
        end
      end
    end
  end

  def create_property_from_modal
    @property = @lead.properties.new(property_params)
    @property.address.owner = @property
    if @property.save
      render "properties/modals/create_property_from_modal"
    end
  end

  def edit
    @lead = @property.lead
    set_referring_page_with_backup(lead_path(@lead))
  end

  def update
    respond_to do |format|
      if @property.update(property_params)
        format.html do
          redirect_to(
            session[:referring_page] || lead_path(@lead),
            notice: "Property was successfully updated."
          )
        end
        format.json { head :no_content }
      else
        format.html do
          set_referring_page
          flash.now[:danger] = handle_error_message
          render :edit
        end
        format.json { render json: @lead.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @property.destroy
    respond_to do |format|
      format.html { redirect_to lead_path(@lead) }
      format.json { head :no_content }
    end
  end

  def set_level_of_interest
    if @property.update_attributes(level_of_interest: params[:level_of_interest])
      redirect_to(
        request.referer || lead_path(@property.lead),
        notice: "Successfully changed interest level."
      )
    else
      redirect_to(
        request.referer || lead_path(@property.lead),
        notice: "Error updating property."
      )
    end
  end

  def refresh_image
    Property.call_api(@property.id)

    if Property.find(params[:id]).property_image
      redirect_to(
        @lead,
        notice: "We were able to find an image for this property!"
      )
    else
      redirect_to(
        @lead,
        notice: "Sorry we cannot currently find an image for this property"
      )
    end
  end

  def get_info_from_address
    # options = { full_address: params[:address_info] }
    @property_info = nil # PropertyApiResearchService.new(options).get_property_info
    if @property_info.present?
      @property_details = @property_info["results"]["property_details"][0]
    end
  end

  private

  def set_property
    @property = Property.find(params[:id])
  end

  def set_lead
    @lead = Lead.find(params[:lead_id])
  end

  def property_params
    unsanitized_params = params.require(:property).permit(
      :bathrooms,
      :bedrooms,
      :commission_fee,
      :commission_fee_buyer_side,
      :commission_fee_total,
      :commission_percentage,
      :commisison_percentage_buyer_side,
      :commission_percentage_total,
      :commission_type,
      :initial_client_valuation,
      :initial_agent_valuation,
      :lead_id,
      :level_of_interest,
      :list_price,
      :listing_expires_at,
      :lot_size,
      :mls_number,
      :notes,
      :original_list_date_at,
      :original_list_price,
      :property_type,
      :property_url,
      :rental,
      :sq_feet,
      :transaction_type,
      :user_id,
      address_attributes: [
        :city,
        :id,
        :require_basic_address_validations,
        :state,
        :street,
        :zip
      ]
    )

    FieldSanitizers::FieldCleaner.new(params: unsanitized_params).scrub_property_fields
  end

  def handle_error_message
    error_message = []
    error_message << "Please check your entry and try again."
    if @property.errors[:"address.base"].present?
      error_message << @property.errors[:"address.base"].join("")
    end

    error_message.join(" ")
  end

end
