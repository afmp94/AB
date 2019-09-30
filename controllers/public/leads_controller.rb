class Public::LeadsController < ApplicationController

  skip_before_action :authenticate_user!
  before_action :load_lead, only: [:claim, :unclaimed, :refer_lead]

  def new
    @user = user_by_key
    @lead = @user.leads.new

    @contact = @lead.build_contact
    @contact.addresses.build
    @contact.phone_numbers.build
    @contact.email_addresses.build
    @properties = @lead.properties.build
    @properties.build_address
  end

  def create
    @user = user_by_key
    @lead = @user.leads.new(lead_params)
    created_by_user_logged_in = (current_user == @user)
    @lead.init_public_lead_details @user, created_by_user_logged_in
    @lead.contact.created_by_user = @user

    if @lead.save
      @lead.notify_about_public_lead_generation created_by_user_logged_in
      redirect_to(
        new_public_lead_path(key: params[:key]),
        notice: "It's in. The new lead has been created."
      )
    else
      flash.now[:notice] = "Uh oh. Something is wrong with your form. Check it and try again."
      render action: "new"
    end
  end

  def unclaimed
    @user_id = current_user ? current_user.id : params[:user_id]
    if @lead.claimed?
      if current_user && @lead.user == current_user
        redirect_to(
          lead_path(@lead),
          notice: "You already claimed this lead for yourself!"
        )
      end
      unless current_user && [@lead.user, @lead.created_by_user].include?(current_user)
        redirect_to(
          claim_public_lead_path(@lead, user_id: @user_id),
          alert: "Lead #{@lead.contact.full_name} has already been claimed by #{@lead.user.full_name}."
        )
      end
    end
    user_for_lead_group_referral_list = current_user || User.find(@user_id)
    @user_lead_groups_owned_or_part_of = user_for_lead_group_referral_list.lead_groups_owned_or_part_of
    @contact = @lead.contact
    @created_by_user = @lead.created_by_user
  end

  def refer_lead
    @lead.refer_to_lead_group(params[:lead_group_id])
    redirect_to(
      unclaimed_public_lead_path(@lead, user_id: current_user.id),
      notice: "Successfully forwarded lead to Lead Group."
    )
  end

  def claim
    if @lead.claimed?
      error_message = "The lead #{@lead.contact.full_name} was already claimed by #{@lead.user.name}."
      if user_signed_in?
        redirect_path = current_user == @lead.user ? lead_path(@lead) : root_path
        redirect_to redirect_path, alert: error_message
      else
        flash.now[:alert] = error_message
      end
    elsif @lead.claim_new_lead(params[:user_id])
      redirect_to(
        lead_path(@lead),
        notice: "You have successfully claimed the lead #{@lead.contact.full_name}."
      )
    else
      flash.now[:notice] = "Error claiming lead!"
    end
  end

  private

  def user_by_key
    User.find_by!(lead_form_key: params[:key])
  end

  def load_lead
    @lead = Lead.find(params[:id])
  end

  def lead_params
    params.require(:lead).permit(
      :additional_fees,
      :amount_owed,
      :attempted_contact_at,
      :buyer,
      :buyer_address,
      :buyer_agent,
      :buyer_area_of_interest,
      :buyer_city,
      :buyer_prequalified,
      :buyer_state,
      :buyer_zip,
      :claimed,
      :client_type,
      :closing_price,
      :contact_id,
      :contacted_status,
      :contingencies,
      :incoming_lead_address,
      :incoming_lead_at,
      :incoming_lead_city,
      :incoming_lead_state,
      :incoming_lead_message,
      :incoming_lead_mls,
      :incoming_lead_price,
      :incoming_lead_url,
      :incoming_lead_zip,
      :initial_property_interested_in,
      :initial_status_when_created,
      :lead_source_id,
      :lead_type_id,
      :listing_address,
      :listing_agent,
      :listing_city,
      :listing_state,
      :listing_zip,
      :lost_date_at,
      :max_price_range,
      :mls_id,
      :min_price_range,
      :name,
      :next_action_id,
      :notes,
      :original_list_date_at,
      :original_list_price,
      :pause_date_at,
      :prequalification_amount,
      :property_type,
      :reason_for_loss,
      :reason_for_pause,
      :referral_fee_flat_fee,
      :referral_fee_rate,
      :referral_fee_type,
      :referring_contact_id,
      :rental,
      :seller,
      :status,
      :stage,
      :stage_lost,
      :stage_paused,
      :timeframe,
      :total_commission_percentage,
      :unpause_date_at,
      :user_id,
      contact_attributes: [
        :first_name,
        :id,
        :last_name,
        addresses_attributes: [
          :city,
          :id,
          :state,
          :street,
          :zip,
        ],
        email_addresses_attributes: [
          :email,
          :id
        ],
        phone_numbers_attributes: [
          :id,
          :number,
        ]
      ],
      properties_attributes: [
        :bedrooms,
        :bathrooms,
        :commission_fee,
        :commission_percentage,
        :commission_type,
        :id,
        :initial_agent_valuation,
        :initial_client_valuation,
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
        :_destroy,
        address_attributes: [
          :city,
          :id,
          :state,
          :street,
          :zip,
        ]
      ]
    )
  end

end
