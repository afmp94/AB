class LeadsController < ApplicationController

  include RecentActivities

  before_action :set_lead, only: [
    :claim,
    :destroy,
    :edit,
    :edit_fixed_list,
    :edit_lead_header,
    :needs_info_to_update_status,
    :not_converting,
    :open_add_property_modal,
    :open_dotloop_modal,
    :open_junk_modal,
    :open_long_term_prospect_modal,
    :open_not_converted_modal,
    :open_pause_modal,
    :open_set_next_action_modal,
    :open_snooze_modal,
    :pause,
    :refer_lead,
    :remind_me_later,
    :set_attempted_contact_status,
    :set_contacted_status,
    :set_long_term_prospect,
    :set_next_action,
    :show,
    :snooze,
    :unclaim,
    :unclaimed
  ]
  before_action :set_modal_new_contact, only: [:edit, :new]
  before_action :set_page_params, only: [:index, :search_leads, :user_leads]
  before_action :check_restrictions, only: [:merge_leads]

  def index
    # add_breadcrumb "Clients", :clients_path
    @current_status = params[:current_status] || "current_pipeline"
    @leads = Search::Leads.new(current_user).fetch(
      _action_name: "clients",
      status: @current_status,
      order_by: "contacts.first_name",
      sort_direction: "asc",
      page: params[:page]
    )
    @stats_service = Clients::PipelineStatsService.new(current_user)
    set_referring_page(clients_path)
  end

  def user_leads
    # add_breadcrumb "Leads", :user_leads_path
    @current_status = "0"
    @leads = Search::Leads.new(current_user).fetch(
      _action_name: "user_leads",
      status: "lead_all",
      order_by: "leads.created_at",
      sort_direction: "desc",
      page: params[:page]
    )
    set_referring_page(clients_path)
  end

  def show
    @lead = LeadsQuery.new(user_ids: current_user.team_member_ids).call.
            includes(:comments, contact: [:phone_numbers, :email_addresses]).find(params[:id])
    @contact = @lead.contact
    @commentable = @lead
    @comments = @commentable.comments
    @comment = Comment.new
    @showings = @lead.showings
    @user_lead_groups_owned_or_part_of = current_user.lead_groups_owned_or_part_of
    init_lead_view_service
    @not_completed_tasks = @lead.tasks.not_completed.order("due_date_at asc")
    @completed_tasks = @lead.tasks.completed.order("completed_at desc")
    @properties = @lead.buyer_properties
    @active_properties = @lead.buyer_properties.no_contract.active
    @archived_properties = @lead.buyer_properties.archived
    @open_contracts = @lead.contracts.open
    @past_contracts = @lead.contracts.past

    @activities, @activities_url = lead_activities(@lead, params[:activity_feed_page])
  end

  def new
    @lead = current_user.leads.new contact_id: params[:contact_id]
    @properties = @lead.properties.build
    @properties.build_address
    set_referring_page
  end

  def new_lead_lead
    @lead = current_user.leads.new
    @contact = @lead.build_contact
    @contact.addresses.build
    @contact.phone_numbers.build
    @contact.email_addresses.build
    @properties = @lead.properties.build
    @properties.build_address
    set_referring_page
  end

  def edit
    render
    set_referring_page
  end

  def create
    @user = current_user
    @lead = @user.leads.new(lead_params)
    @lead.created_by_user = current_user
    @lead.incoming_lead_at = Time.zone.now
    @lead.contacted_status = 3
    @lead.state = "claimed"
    if @lead.save
      redirect_to(
        decide_redirect_path(@lead, params[:from_page]),
        notice: "Lead was successfully created."
      )
    else
      set_modal_new_contact
      flash.now[:danger] = "Please check your entry and try again."
      render :new
    end
  end

  def create_new_lead
    @user = current_user
    @lead = @user.leads.new(lead_params)
    @lead.created_by_user = current_user
    @lead.incoming_lead_at = Time.zone.now
    @lead.state = "claimed"
    @lead.status = 0
    @contact = @lead.contact.nil? ? current_user.contacts.new : @lead.contact
    @contact.user_id = @user.id
    @contact.addresses.build

    if @lead.save && @contact.save
      @contact.call_contact_api
      redirect_to(
        session[:referring_page] || @lead,
        notice: "Lead was successfully created."
      )
    else
      flash.now[:danger] = handle_error_message
      render :new_lead_lead
    end
  end

  def update
    @lead = Lead.find(params[:id])
    @contact = @lead.contact
    @inline_form = params[:inline_form]

    if @lead.user_id.nil? && lead_params[:status] == "7"
      params[:lead][:user_id] = current_user.id
    end

    respond_to do |format|
      if @lead.update(lead_params)
        format.html do
          redirect_to(
            session[:referring_page] || @lead,
            notice: "Lead was successfully updated."
          )
        end
        format.json { head :no_content }
        format.js { flash.now[:notice] = "Saved!" } unless forced_form_for_mobile_app?
      else
        flash.now[:danger] = "Please check your entry and try again."

        format.html do
          render :edit
        end

        format.json { render json: @lead.errors, status: :unprocessable_entity }
        format.js unless forced_form_for_mobile_app?
      end
    end
  end

  def destroy
    @lead.destroy
    respond_to do |format|
      format.html { redirect_to leads_url }
      format.json { head :no_content }
    end
  end

  def destroy_multiple
    Lead.transaction do
      if lead_ids = params[:ids]
        lead_ids.each { |id| LeadsQuery.new(user_ids: current_user.team_member_ids).call.find(id).destroy }
      end
    end

    respond_to do |format|
      format.html { redirect_to leads_url }
      format.json { head :no_content }
    end
  end

  def search_leads
    @leads = Search::Leads.new(current_user).fetch(
      _action_name: params[:action_name],
      status: params[:status],
      order_by: params[:order_by],
      sort_direction: params[:sort_direction],
      search_term: params[:search_term],
      page: params[:page]
    )

    render layout: false
  end

  def search_for_autocomplete
    search_results = []

    leads = if params[:include_team_leads] == "true"
              current_user.team_leads.open_clients_and_leads.order("name asc")
            else
              current_user.leads.open_clients_and_leads.order("name asc")
            end

    leads = leads.search_name(params[:search_term])

    leads.each do |lead|
      search_results << {
        lead_name: lead.name,
        lead_id: lead.id
      }
    end

    render json: { "results": search_results, "success": true }
  end

  def claim
    if @lead.claimed?
      error_message = "Lead #{@lead.contact.full_name} has already been claimed."
      redirect_path = current_user == @lead.user ? lead_path(@lead) : root_path
      redirect_to redirect_path, notice: error_message
    elsif @lead.claim_new_lead(params[:user_id])
      redirect_to lead_path(@lead), notice: "You have successfully claimed lead #{@lead.contact.full_name}."
    else
      redirect_to lead_path(@lead), notice: "Error claiming lead!"
    end
  end

  def unclaim
    if @lead.can_be_unclaimed?
      @lead.unclaim!
      flash[:notice] = "Lead was successfully unclaimed!"
    else
      flash[:alert] = "Could not unclaim lead, sorry."
    end

    respond_to do |format|
      format.html { redirect_to @lead }
      format.json { head :no_content }
    end
  end

  def unsnooze
    @lead = LeadsQuery.new(user_ids: current_user.team_member_ids).call.find(params[:id])
    @lead.snoozed_by_id = nil
    @lead.snoozed_until = nil
    @lead.snoozed_at = nil
    if @lead.save
      flash[:notice] = "Lead was successfully unsnoozed!"
    else
      flash[:alert] = "Could not unsnooze lead, sorry."
    end

    respond_to do |format|
      format.html { redirect_to @lead }
      format.json { head :no_content }
    end
  end

  def refer_lead
    @lead.refer_to_lead_group(params[:lead_group_id])
    redirect_to(
      lead_path(@lead, user_id: current_user.id),
      notice: "You successfully forwarded this lead."
    )
  end

  def needs_info_to_update_status
    @new_status = params[:new_status]
    @contract_params = if @new_status == "4"
                         { status: "closed" }
                       else
                         {}
                       end

    if @new_status == "4" && !@lead.broker_commission_defined? && !@lead.user.broker_commission_defined?
      flash[:error] = "Contract requires the Lead to have a broker splits value"\
        " defined/set yet. Please update the Commission details in"\
        " the Owner Agent's Profile."

      redirect_to lead_path(@lead)
    else
      render "leads/needs_info_to_update_status"
    end
  end

  def set_contacted_status
    if @lead.update_attributes(contacted_status: params[:contacted_status_id])
      redirect_to request.referer || lead_path(@lead), notice: "Successfully updated lead."
    else
      redirect_to request.referer || lead_path(@lead), notice: "Error updating lead."
    end
  end

  def set_attempted_contact_status
    if @lead.update_attributes(contacted_status: params[:contacted_status_id], attempted_contact_at: Time.zone.now)
      redirect_to redirect_path, notice: "Successfully updated lead."
    else
      redirect_to redirect_path, notice: "Error updating lead."
    end
  end

  def not_converting
    if @lead.mark_as_not_converting(lead_params)
      redirect_to redirect_path, notice: "Successfully marked Lead as not converted."
    else
      redirect_to redirect_path, notice: "Error marking Lead as not converted."
    end
  end

  def set_next_action
    set_referring_page || tasks_path
    @task = @lead.tasks.new
    @task.assigned_to = current_user
  end

  def edit_fixed_list
    lead_type = params[:lead_type]
    section   = params[:section]

    if section == "client_info"
      build_email_phone_address
    end

    render "leads/#{lead_type}/js/edit_#{section}"
  end

  def edit_lead_header
    build_email_phone_address
    render "leads/header/edit_lead_header"
  end

  def remind_me_later
    remind_time = Time.zone.now + params[:delay_time].to_i.hours
    lead = Lead.find(params[:lead_id])
    lead.lead_followup_reminder_time = remind_time

    if lead.save
      respond_to do |format|
        format.json { render json: "success", msg: "Lead updated" }
      end
    else
      respond_to do |format|
        format.json { render json: "fail", msg: "Lead not updated" }
      end
    end
  end

  def open_pause_modal
    render "leads/modals/open_pause_modal"
  end

  def pause
    if @lead.mark_as_paused(lead_params)
      redirect_to redirect_path, notice: "Successfully marked Lead as paused."
    else
      redirect_to redirect_path, notice: "Error marking Lead as paused."
    end
  end

  def open_long_term_prospect_modal
    render "leads/modals/open_long_term_prospect_modal"
  end

  def set_long_term_prospect
    if @lead.mark_as_long_term_prospect(lead_params)
      redirect_to redirect_path, notice: "Successfully marked lead as long term prospect."
    else
      redirect_to redirect_path, notice: "Error marking lead as long term prospect."
    end
  end

  def open_snooze_modal
    render "leads/modals/open_snooze_modal"
  end

  def snooze
    @lead = LeadsQuery.new(user_ids: current_user.team_member_ids).call.find(params[:id])
    set_snooze_params
    if @lead.save
      redirect_back(fallback_location: lead_path(@lead), notice: "#{@lead.name} has been snoozed.")
    else
      redirect_back(fallback_location: lead_path(@lead), danger: "Error snoozing #{@lead.name}.")
    end
  end

  def open_dotloop_modal
    @message = "You have reached your LOOP limit in DOTLOOP. Please sign in to DOTLOOP to upgrade."
    @token = DotloopService.new.refresh_dotloop_token(current_user)
    set_dotloop_client = DotloopService.new.set_dotloop_client(current_user)
    if @token
      @profiles = DotloopService::Profile.new.fetch_all(set_dotloop_client)
      profile_ids = @profiles.map(&:id)
      @profile_loops = DotloopService::Template.new.fetch_all_loops(set_dotloop_client, profile_ids)
      @templates =  DotloopService::Template.new.fetch_all(set_dotloop_client, profile_ids)
      @message = ""
    end
    render "leads/modals/open_dotloop_modal"
  end

  def open_junk_modal
    render "leads/modals/open_junk_modal"
  end

  def mark_as_junk
    @lead = Lead.find(params[:id])
    reason = params[:junk_reason]

    @lead.status = 7
    # for junk leads in unclaimed state
    if @lead.user_id.nil?
      @lead.user_id = current_user.id
    end

    @lead.junk_reason = reason
    if @lead.save
      redirect_back(fallback_location: lead_path(@lead), notice: "#{@lead.name} has been junked.")
    else
      redirect_back(fallback_location: lead_path(@lead), danger: "Error junking #{@lead.name}.")
    end
  end

  def open_add_property_modal
    @property = @lead.properties.new(
      transaction_type: "Buyer",
      level_of_interest: "Interested",
    )
    @property.build_address
    render "properties/modals/add_property"
  end

  def open_set_next_action_modal
    @task = @lead.tasks.new
    @task.assigned_to = current_user

    render "leads/modals/open_set_next_action_modal"
  end

  def open_not_converted_modal
    render "leads/modals/open_not_converted_modal"
  end

  def open_judge_lead_modal
    @lead = LeadsQuery.new(user_ids: current_user.team_member_ids).call.find(params[:id])
    set_referring_page
    render "leads/modals/open_judge_lead_modal"
  end

  def open_merge_lead_modal
    @lead = current_user.leads.find(params[:id])
    query = if @lead.status == 0
              "status = ?"
            else
              "status != ?"
            end

    @all_leads = current_user.leads.where("id != ? AND #{query}", @lead.id, 0)
    render "leads/modals/open_merge_lead_modal"
  end

  def merge_leads
    lead_ids = params[:lead_ids].map(&:to_i)
    primary_lead = LeadMerger.new(lead_ids).merge
    if primary_lead
      flash[:notice] = "Leads Merged Successfully"
      redirect_to primary_lead
    else
      flash[:error] = "Something went wrong! Unable to merge leads"
      redirect_back fallback_location: request.referer
    end
  end

  private

  def set_lead
    @lead = LeadsQuery.new(user_ids: current_user.team_member_ids).call.find_by(id: params[:id])
  end

  def set_modal_new_contact
    @contact = current_user.contacts.new
    @contact.addresses.build
    @contact.email_addresses.build
    @contact.phone_numbers.build
  end

  def redirect_path
    set_referring_page_with_backup(lead_path(@lead))
  end

  def init_lead_view_service
    @lead_view_service = LeadViewService.new(@lead)
  end

  def handle_error_message
    error_message = []
    error_message << "Please check your entry and try again."
    error_message << @lead.errors[:"contact.base"].join("") if @lead.errors[:"contact.base"].present?

    error_message.join(" ")
  end

  def decide_redirect_path(lead, from_page=nil)
    redirect_path = lead

    if from_page == FromPage::CONTACTS_INDEX
      redirect_path = lead
    elsif from_page == FromPage::CONTACTS_SHOW
      redirect_path = lead
    elsif session[:referring_page].present?
      redirect_path = session[:referring_page]
    end

    redirect_path
  end

  def set_snooze_params
    @lead.snoozed_until = Time.zone.now + params[:snooze_time].to_i.hours
    @lead.snoozed_by = current_user
    @lead.snoozed_at = Time.zone.now
  end

  def set_page_params
    if params[:page]
      session[:client_index_page] = params[:page]
      session[:lead_index_page] = params[:page]
    else
      session[:client_index_page] = nil
      session[:lead_index_page] = nil
    end
  end

  def lead_params
    unsanitized_leads_params = lead_attributes

    FieldSanitizers::LeadFields.new(unsanitized_leads_params).process
  end

  def build_email_phone_address
    contact = @lead.contact
    contact.addresses.build if contact.addresses.blank?
    contact.phone_numbers.build if contact.phone_numbers.blank?
    contact.email_addresses.build if contact.email_addresses.blank?
  end

  def lead_attributes
    params.require(:lead).permit(
      :activate_contact,
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
      :displayed_broker_commission_custom,
      :displayed_broker_commission_fee,
      :displayed_broker_commission_percentage,
      :displayed_broker_commission_type,
      :incoming_lead_address,
      :incoming_lead_at,
      :incoming_lead_city,
      :incoming_lead_mls,
      :incoming_lead_message,
      :incoming_lead_price,
      :incoming_lead_state,
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
      :long_term_prospect_remind_me_at,
      :lost_date_at,
      :max_price_range,
      :min_price_range,
      :mls_id,
      :name,
      :next_action_id,
      :notes,
      :original_list_date_at,
      :original_list_price,
      :pause_date_at,
      :prequalification_amount,
      :property_type,
      :reason_for_long_term_prospect,
      :reason_for_loss,
      :reason_for_pause,
      :referral_fee_flat_fee,
      :referral_fee_rate,
      :referral_fee_type,
      :referring_contact,
      :referring_contact_id,
      :stage,
      :stage_lost,
      :stage_paused,
      :rental,
      :seller,
      :status,
      :timeframe,
      :total_commission_percentage,
      :unpause_date_at,
      :user_id,
      contact_attributes: [
        :first_name,
        :id,
        :last_name,
        :require_basic_validations,
        :spouse_first_name,
        :spouse_last_name,
        :user_id,
        addresses_attributes: [
          :city,
          :id,
          :state,
          :street,
          :zip,
          :require_basic_address_validations,
        ],
        email_addresses_attributes: [
          :email,
          :id
        ],
        phone_numbers_attributes: [
          :id,
          :number
        ]
      ],
      properties_attributes: [
        :_destroy,
        :bathrooms,
        :bedrooms,
        :commission_fee,
        :commission_fee_buyer_side,
        :commission_fee_total,
        :commission_percentage,
        :commission_percentage_buyer_side,
        :commission_percentage_total,
        :commission_type,
        :id,
        :initial_agent_valuation,
        :initial_client_valuation,
        :initial_property_interested_in,
        :level_of_interest,
        :list_price,
        :listing_expires_at,
        :lot_size,
        :mls_number,
        :notes,
        :original_list_date_at,
        :original_list_price,
        :property_url,
        :property_type,
        :rental,
        :sq_feet,
        :trackable_lead_activity,
        :transaction_type,
        address_attributes: [
          :city,
          :id,
          :state,
          :street,
          :zip
        ]
      ],
      contracts_attributes: [
        :additional_fees,
        :buyer,
        :buyer_agent,
        :closing_date_at,
        :closing_price,
        :commission_flat_fee,
        :commission_rate,
        :commission_type,
        :commission_percentage_total,
        :commission_percentage_buyer_side,
        :commission_fee_buyer_side,
        :commission_fee_total,
        :id,
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
      ],
      key_people_attributes: [
        :contact_id,
        :lead_id,
        :role_type
      ]
    )
  end

  def check_restrictions
    lead_merger = LeadMerger.new(params[:lead_ids])
    secondry_lead = Lead.find((params[:lead_ids] - [lead_merger.primary_lead.id.to_s])[0])
    restriction(secondry_lead)
  end

  def restriction(secondry_lead)
    leads = Lead.find(params[:lead_ids])
    if leads.pluck(:client_type).uniq.length > 1
      flash[:error] = "You cannot merge a buyer and a seller record"
      redirect_back fallback_location: request.referer
    elsif [3, 4].include?(secondry_lead.status)
      flash[:error] = "You cannot merge a lead having status pending or closed"
      redirect_back fallback_location: request.referer
    end
  end

end
