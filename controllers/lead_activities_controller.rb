class LeadActivitiesController < ApplicationController

  before_action :set_lead, only: [:open_call_result_modal, :open_response_modal,
                                  :open_reply_to_lead_email_modal]

  before_action :set_lead_activity, only: [:show, :edit, :update, :destroy]

  def new
    @lead_activity = build_lead_activity
  end

  def create
    @lead_activity = build_lead_activity(lead_activity_attributes)
    if @lead_activity.save!
      redirect_to(
        new_lead_activity_path,
        notice: "Your new activity has been successfully created!"
      )
    else
      flash.now[:danger] = "Please check your entry and try again."
      render :new
    end
  end

  def show
    redirect_to(edit_lead_activity_url(params[:id]))
  end

  def edit
    render
  end

  def update
    if @lead_activity.update(lead_activity_attributes)
      redirect_to(
        lead_activity_path,
        notice: "Lead activity was successfully updated."
      )
    else
      flash.now[:danger] = "Please check your entry and try again."
      render :edit
    end
  end

  def destroy
    @lead_activity.destroy
    redirect_to(dashboard_url)
  end

  def open_call_result_modal
    @lead_activity = build_lead_activity(lead_id: @lead.id)
    @lead_activity.activity_type = "Call"
    @lead_activity.user = current_user
    render "lead_activities/modals/open_call_result_modal"
  end

  def record_call_result
    @lead_activity = build_lead_activity(lead_activity_attributes)
    @lead = Lead.find(@lead_activity.lead_id)
    set_call_result_attributes
    if @lead_activity.save!
      update_lead
      redirect_to(
        @lead,
        notice: "Your new activity has been successfully created!"
      )
    else
      flash.now[:danger] = "Please check your entry and try again."
      render :new
    end
  end

  def record_response
    @lead_activity = build_lead_activity(lead_activity_attributes)
    @lead = Lead.find(@lead_activity.lead_id)
    set_response_attributes

    if @lead_activity.save!
      update_lead
      redirect_to(
        @lead,
        notice: "Your new activity has been successfully created!"
      )
    else
      flash.now[:danger] = "Please check your entry and try again."
      render :new
    end
  end

  def open_response_modal
    @lead_activity = build_lead_activity(lead_id: @lead.id)
    render "lead_activities/modals/open_response_modal"
  end

  def open_reply_to_lead_email_modal
    render "lead_activities/modals/open_reply_to_lead_email_modal"
  end

  private

  def set_lead_activity
    @lead_activity = ContactActivity.find(params[:id])
  end

  def set_lead
    @lead = Lead.find(params[:lead_id])
  end

  def build_lead_activity(attributes={})
    ContactActivity.new(
      user: current_user,
      activity_for: ContactActivity::ACTIVITY_FOR[1],
      contact: find_contact_by_lead_id_in_attributes(attributes),
      attributes: attributes
    )
  end

  def find_contact_by_lead_id_in_attributes(attributes)
    unless attributes.empty?
      Lead.find(attributes[:lead_id]).contact
    end
  end

  def set_call_result_attributes
    call_result = params[:call_result]
    @lead_activity.completed_at = Time.current
    lead_name = @lead.contact.full_name

    if call_result == "Yes"
      @lead_activity.subject = "Called and talked to #{lead_name}"
    elsif call_result == "No"
      @lead_activity.subject = "Tried calling #{lead_name} but there was no answer"
    elsif call_result == "Left Message"
      @lead_activity.subject = "Called #{lead_name} and left a message"
    end
  end

  def set_response_attributes
    params[:call_result] = "Yes"
    @lead_activity.subject = "Received #{@lead_activity.activity_type&.downcase} from #{@lead.contact.full_name}"
  end

  def update_lead
    case params[:call_result]
    when "Yes"
      LeadContactedStatusUpdater.new(@lead).set_as_contacted(params[:lead_status].to_i)
    when "No"
      LeadContactedStatusUpdater.new(@lead).set_as_attempted_contact
      FollowUp.new(@lead).set(params[:no_answer_follow_up_time].to_i)
    when "Left Message"
      LeadContactedStatusUpdater.new(@lead).set_as_awaiting_reply
      FollowUp.new(@lead).set(params[:left_message_follow_up_time].to_i)
    end

    @lead.set_long_term_prospect_remind_me_at(params[:long_term_prospect_remind_me_at])

    @lead.save!
  end

  def lead_activity_attributes
    params.
      require(:contact_activity).
      permit(
        :activity_for,
        :activity_type,
        :asked_for_referral,
        :comments,
        :completed_at,
        :contact_id,
        :custom_time,
        :lead_id,
        :subject,
        :user_id,
      )
  end

end
