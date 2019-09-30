class ContractsController < ApplicationController

  before_action(
    :set_contract,
    only: [:destroy, :edit, :set_status, :update]
  )
  before_action :set_lead, only: [:create, :new]

  def new
    @property = Property.find(params[:property_id])
    @contract = @property.contracts.new
    @contract.additional_fees = @property.lead.additional_fees
    @contract.referral_fee_type = @property.lead.referral_fee_type
    @contract.referral_fee_rate = @property.lead.referral_fee_rate
    @contract.referral_fee_flat_fee = @property.lead.referral_fee_flat_fee
    @contract.contingencies.build
    if @lead.client_type == "Seller"
      @contract.commission_type = @property.commission_type
      @contract.commission_rate = @property.commission_percentage
      @contract.commission_flat_fee = @property.commission_fee
    end
    @contract.additional_fees = @property.lead.additional_fees
    @contract.referral_fee_type = @property.lead.referral_fee_type
    @contract.referral_fee_rate = @property.lead.referral_fee_rate
    @contract.referral_fee_flat_fee = @property.lead.referral_fee_flat_fee
  end

  def add_contract
    @lead = Lead.find(params[:lead_id])
    @contract = @lead.contracts.new
    if @lead.additional_fees.present?
      @contract.additional_fees = @lead.additional_fees
    end
    if @lead.referral_fee_type.present?
      @contract.referral_fee_type = @lead.referral_fee_type
    end
    if @lead.referral_fee_rate?
      @contract.referral_fee_rate = @lead.referral_fee_rate
    end
    if @lead.referral_fee_flat_fee.present?
      @contract.referral_fee_flat_fee = @lead.referral_fee_flat_fee
    end
  end

  def create
    @property = Property.find(params[:property_id] || params[:contract][:property_id])
    @contract = @property.contracts.new(contract_params)
    @contract.lead = @lead

    @redirect_page = params[:redirect_page]
    @render_page   = params[:render_page]

    respond_to do |format|
      Task.transaction do
        # Revert back contract insert when Task gets any error.
        if @contract.save
          Task.for_client_testimonial(current_user, @lead, @contract)
          format.html do
            redirect_to redirect_to_path, notice: "Contract added successfully!"
          end

          format.js unless forced_form_for_mobile_app?
        else
          format.html do
            flash.now[:danger] = "Please check your entry and try again."
            render render_action
          end
        end
      end
    end
  end

  def edit
    render
  end

  def update
    @redirect_page = params[:redirect_page]
    @render_page   = params[:render_page]

    respond_to do |format|
      if @contract.update(contract_params)
        format.html do
          redirect_to redirect_to_path, notice: "Contract updated successfully!"
        end
        format.js unless forced_form_for_mobile_app?
      else
        format.html do
          flash.now[:danger] = "Please check your entry and try again."
          render render_action
        end
      end
    end
  end

  def destroy
    @contract = Contract.find(params[:id])
    @property = @contract.property
    @lead = @property.lead
    @contract.destroy
    respond_to do |format|
      format.html { redirect_to @lead }
      format.json { head :no_content }
    end
  end

  def set_status
    if (params[:status] == "pending_contingencies" ||
       params[:status] == "ready_to_close" || params[:status] == "closed") &&
       @contract.other_accepted_contract?
      redirect_to @lead, danger: "You can only have one pending or closed contract at a time."
    elsif @contract.update_attribute :status, params[:status]
      redirect_to @lead, notice: "Successfully updated contract status."
    else
      redirect_to @lead, notice: "Error updating contract status."
    end
  end

  private

  def set_contract
    @contract = Contract.find(params[:id])
    @property = @contract.property
    @lead = @property.lead
  end

  def set_lead
    @lead = Lead.find(params[:lead_id])
  end

  def sanitize_price_fields_params(contracts_params)
    [
      :additional_fees,
      :closing_price,
      :commission_fee_buyer_side,
      :commission_fee_total,
      :commission_flat_fee,
      :offer_price,
      :referral_fee_flat_fee
    ].each do |price_field|
      if contracts_params[price_field].present?
        contracts_params[price_field] = sanitize_price(contracts_params[price_field])
      end
    end

    contracts_params
  end

  def sanitize_price(price_value)
    price_value.delete(",")
  end

  def contract_params
    unsanitized_contracts_params = params.require(:contract).permit(
      :additional_fees,
      :broker_commission_custom,
      :broker_commission_fee,
      :broker_commission_percentage,
      :broker_commission_type,
      :buyer,
      :buyer_agent,
      :closing_date_at,
      :closing_price,
      :commission_fee_buyer_side,
      :commission_fee_total,
      :commission_percentage_buyer_side,
      :commission_percentage_total,
      :contract_type,
      :commission_type,
      :commission_rate,
      :commission_flat_fee,
      :lead_id,
      :offer_accepted_date_at,
      :offer_deadline_at,
      :offer_price,
      :property_id,
      :referral_fee_flat_fee,
      :referral_fee_rate,
      :referral_fee_type,
      :seller,
      :seller_agent,
      :status,
      contingencies_attributes: [
        :_destroy,
        :id,
        :name,
        :status
      ]
    )

    sanitize_price_fields_params(unsanitized_contracts_params)
  end

  def redirect_to_path
    if params[:redirect_page].present?
      return leads_path if params[:redirect_page] == "leads_index"
      return lead_path(@lead) if params[:redirect_page] == "leads_show"
      clients_path
    else
      clients_path
    end
  end

  def render_action
    if params[:render_page].present?
      return :new if params[:render_page] == "contracts_new_buyer"
      return :new if params[:render_page] == "contracts_new_seller"
      return :edit if params[:render_page] == "contracts_edit_buyer"
      return :edit if params[:render_page] == "contracts_edit_seller"
      return :add_contract if params[:render_page] == "contracts_add_contract"
      :new
    else
      :new
    end
  end

end
