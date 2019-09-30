class EmailCampaignsController < ApplicationController

  before_action :load_email_campaign, only: [
    :delete,
    :destroy,
    :edit,
    :edit_basic,
    :preview_market_data,
    :replicate,
    :schedule,
    :send_now,
    :send_preview,
    :show,
    :update,
    :update_email_message_info,
    :contact_activity_report,
    :search_recipients
  ]

  before_action :load_email_campaigns, only: [:index, :search_email_campaigns]

  def index
    render
  end

  def old_index
    @email_campaigns = current_user.email_campaigns.order("updated_at desc")
  end

  def show
    @report = EmailCampaign::ContactActivityReportService.new(@email_campaign)
    @campaign_messages = @email_campaign.campaign_messages.includes(:contact)
  end

  def create
    options = {
      name: "Draft",
      campaign_status: 0,
      track_opens: current_user.email_campaign_track_opens,
      track_clicks: current_user.email_campaign_track_clicks
    }

    if params[:campaign_type].present?
      options[:campaign_type] = params[:campaign_type]
    end

    campaign = current_user.email_campaigns.build(options)

    if campaign.save!
      if campaign.campaign_type == EmailCampaign::CAMPAIGN_TYPES[:basic]
        redirect_to(edit_basic_email_campaign_path(campaign))
      else
        redirect_to(edit_email_campaign_path(campaign))
      end
    else
      redirect_to(
        email_campaigns_path,
        notice: "Sorry there was an error creating your email campaign, please try again"
      )
    end
  end

  def edit
    @user_altered_email = EmailCampaign::AlerternateDomainsService.new(current_user.email).fetch

    if @email_campaign.draft?
      render
    else
      redirect_to email_campaign_path(@email_campaign)
    end
  end

  def edit_basic
    @user_altered_email = EmailCampaign::AlerternateDomainsService.new(current_user.email).fetch

    if @email_campaign.draft?
      render
    else
      redirect_to email_campaign_path(@email_campaign)
    end
  end

  def update
    if params[:autosave]
      autosave_campaign
    elsif @email_campaign.update(email_campaign_params)
      if params[:update_recipient_count] == "true"
        render "email_campaigns/update_recipient_count"
      else
        redirect_to(email_campaigns_path, notice: "Campaign saved.")
      end
    else
      flash.now[:danger] = "Error saving campaign."
      render :edit
    end
  end

  def delete
    @email_campaign.destroy
    respond_to do |format|
      format.html { redirect_to email_campaigns_path }
      format.json { head :no_content }
    end
  end

  def destroy
    @email_campaign.destroy
    respond_to do |format|
      format.html { redirect_to email_campaigns_path }
      format.json { head :no_content }
    end
  end

  def search_email_campaigns
    render layout: false
  end

  def send_preview
    if current_user.confirmed?
      email_lists = params[:test_email_recipients]
      report = MarketReportMessage.new(
        email_campaign_id: @email_campaign.id,
      )

      mg_campaign_service = MailgunApi::SendMessageForCampaignService.new
      mg_campaign_service.delay.process_preview(@email_campaign, email_lists, report)

      respond_to do |format|
        format.js do
          flash.now[:notice] = "Email campaign was successfully scheduled for delivery"
        end
      end
    else
      respond_to do |format|
        format.js do
          flash.now[:error] = "Your email address is not confirmed yet. Please go to your profile page."
        end
      end
    end
  end

  def send_now
    if current_user.confirmed?
      mg_campaign_service = MailgunApi::SendMessageForCampaignService.new
      mg_campaign_service.delay.process(@email_campaign)

      # Not sure about how to handle `@email_campaign.delivered` and
      # `@email_campaign.delivered_at` in proper way.
      #
      # Means should we consider 'status' propery in mandrill's results
      # response or not? Because sending status of the recipient can be
      # either "sent", "queued", "scheduled", "rejected", or "invalid"
      #
      # Mailgun response if we send multiple emails.
      # [
      #     [0] {
      #                 "email" => "john@example.com",
      #                "status" => "sent",
      #                   "_id" => "c8ed907661dd4a9f9a42fa31f93d4c35",
      #         "reject_reason" => nil
      #     },
      #     [1] {
      #                 "email" => "adam@example.com",
      #                "status" => "invalid",
      #                   "_id" => "3ae9c39815bc41c291b0b2fbf9d1a80b",
      #         "reject_reason" => nil
      #     }
      # ]
      #
      # Currently we don't care about the 'status' property in the response.
      # We just set `email_campaign.delivered` and `email_campaign.delivered_at`
      # if madrill is done with its process.
      @email_campaign.delivered = true
      @email_campaign.delivered_at = Time.zone.now
      @email_campaign.campaign_status = EmailCampaign.campaign_statuses[:pending]
      @email_campaign.save!

      redirect_to(email_campaigns_path, notice: "Email campaign was successfully scheduled for delivery")
    else
      redirect_to(
        email_campaigns_path,
        notice: "Your email address is not confirmed yet. Please go to your profile page."
      )
    end
  end

  def schedule
    if current_user.confirmed?
      schedule_data = {
        deliver_date:  params[:deliver_date],
        delivery_time: params[:delivery_time],
        deliver_time:  params[:deliver_time]
      }

      mg_campaign_service = MailgunApi::SendMessageForCampaignService.new
      mg_campaign_service.schedule_process(@email_campaign, schedule_data)

      @email_campaign.delivered = true
      @email_campaign.delivered_at = Time.zone.now
      @email_campaign.campaign_status = EmailCampaign.campaign_statuses[:scheduled]
      @email_campaign.save!

      redirect_to(email_campaigns_path, notice: "Email campaign was successfully scheduled for delivery")
    else
      redirect_to(
        email_campaigns_path,
        notice: "Your email address is not confirmed yet. Please go to your profile page."
      )
    end
  end

  def destroy_multiple
    EmailCampaign.transaction do
      params[:ids]&.each do |id|
        current_user.email_campaigns.find(id).destroy!
      end
    end

    respond_to do |format|
      format.html { redirect_to contacts_url }
      format.json { head :no_content }
    end
  end

  def contact_activity_report
    @contact         = Contact.find(params[:contact_id])
    campaign_message = CampaignMessage.where(
      email_campaign_id: @email_campaign.id,
      contact_id: @contact.id
    ).first

    if campaign_message
      @activities = campaign_message.campaign_message_events.main_events
      @activities = @activities.select(:event_generated_at, :event_type)
      @activities = @activities.group_by do |activitiy|
        activitiy.event_generated_at.strftime("%m/%d/%Y")
      end
    end
  end

  def replicate
    new_campaign = EmailCampaign.new(
      title: @email_campaign.title,
      image: @email_campaign.image,
      contacts: @email_campaign.contacts,
      content: @email_campaign.content,
      groups: @email_campaign.groups,
      user_id: @email_campaign.user_id,
      campaign_status: 0,
      subject: @email_campaign.subject,
      name: @email_campaign.name + "(copy)",
      campaign_image: @email_campaign.campaign_image,
    )

    if new_campaign.save!
      redirect_to email_campaigns_path, notice: "Successfully replicated campaign"
    else
      redirect_to(
        email_campaigns_path,
        notice: "Sorry there was an error replicating your campaign. Please try again"
      )
    end
  end

  def preview_content_html
    @email_campaign = EmailCampaign.includes(:campaign_image).find(params[:id])
    @user = current_user
    render layout: false
  end

  def preview_market_data
    @report = MarketReportMessage.new(
      email_campaign_id: @email_campaign.id,
      contact_id: params[:contact_id]
    )
    render layout: false
  end

  def update_email_message_info
    @recipient = @email_campaign.recipients.find_by(id: params[:contact_id])
  end

  def search_recipients
    render json: @email_campaign.search_recipients(params[:q])
  end

  private

  def load_email_campaign
    @email_campaign = EmailCampaign.find(params[:id])
  end

  def load_email_campaigns
    search_email_campaigns =
      if params[:search_term].present?
        current_user.email_campaigns.search_name(params[:search_term])
      else
        current_user.email_campaigns
      end

    campaign_status = params[:campaign_status]

    if campaign_status && campaign_status != "all"
      case campaign_status
      when "draft"
        search_email_campaigns = search_email_campaigns.draft
      when "sent"
        search_email_campaigns = search_email_campaigns.sent
      when "all"
        search_email_campaigns = search_email_campaigns.all
      end
    end

    order_by = params[:order_by] || "created_at desc"
    @email_campaigns = search_email_campaigns.order(order_by.to_s).page(params[:page])
  end

  def autosave_campaign
    if @email_campaign.update(email_campaign_params)
      render json: @email_campaign, head: :ok
    else
      render json: @email_campaign.errors, status: :unprocessable_entity
    end
  end

  def email_campaign_params
    params.require(:email_campaign).permit(
      :campaign_status,
      :color_scheme,
      :contacts,
      :content,
      :custom_delivery_time,
      :custom_message,
      :display_custom_message,
      :groups,
      :name,
      :recipient_selector_type,
      :send_generic_report,
      :subject,
      :title,
      :track_clicks,
      :track_opens,
      :campaign_type,
      selected_grades: [],
      selected_groups: [],
      campaign_image_attributes: [:file]
    )
  end

end
