class ActionPlanMembershipsController < ApplicationController

  before_action :set_action_plan_membership, only: %i(cancel open_approval_step_modal send_action_plan_email_message)

  def create
    @action_plan = current_user.action_plans.find_by(id: params[:action_plan_membership][:action_plan_id])
    @action_plan_membership = @action_plan.action_plan_memberships.create!(action_plan_membership_params)
    @action_plan_memberships = @action_plan.action_plan_memberships

    redirect_after_create
  end

  def cancel
    @action_plan = @action_plan_membership.action_plan
    @action_plan_membership.update!(state: :cancelled)
    @action_plan_memberships = @action_plan.action_plan_memberships

    redirect_after_cancel
  end

  def open_approval_step_modal
    @message = @action_plan_membership.next_step.email_template.message_body
    @message = ActionPlanMessageConstructor.new(
      @message,
      @action_plan_membership.contact,
      @action_plan_membership
    ).construct

    render "action_plan_memberships/modals/open_waiting_approval_action_plan_membership"
  end

  def send_action_plan_email_message
    current_step = @action_plan_membership.next_step
    email_template = current_step.email_template
    email_template.message_body = params[:email_template][:message_body]
    contact = @action_plan_membership.contact
    user = contact.user
    step_executer_service = ActionPlanStepExecuter.new

    if step_executer_service.send_email(user, contact, current_step.email_template, @action_plan_membership)
      step_executer_service.update_action_plan_membership_fields(current_step, @action_plan_membership)
      @action_plan_membership.update_attributes(state: "active") if @action_plan_membership.state != "completed"

      flash[:notice] = "Email has been sent!"
    else
      flash[:error] = "Email sending failed!"
    end

    redirect_to contact_path(contact)
  end

  private

  def action_plan_membership_params
    params.require(:action_plan_membership).permit(
      :contact_id,
      :lead_id,
      :lead_status_when_initiated,
      :action_plan_id,
      :state
    )
  end

  def set_action_plan_membership
    @action_plan_membership = ActionPlanMembership.find_by(id: params[:id])
  end

  def redirect_after_create
    respond_to do |format|
      format.html do
        if params[:from_contacts]
          redirect_to contact_path(params[:action_plan_membership][:contact_id])
        elsif params[:from_leads]
          redirect_to lead_path(params[:action_plan_membership][:lead_id])
        else
          redirect_to action_plans_url
        end
      end
      format.js
    end
  end

  def redirect_after_cancel
    respond_to do |format|
      format.html do
        if params[:from_contacts]
          redirect_to(
            contact_path(@action_plan_membership.contact_id),
            notice: "Cancelled successfully."
          )
        elsif params[:from_leads]
          redirect_to(
            lead_path(@action_plan_membership.lead_id),
            notice: "Cancelled successfully."
          )
        else
          redirect_to action_plan_path(@action_plan)
        end
      end
      format.js { render "create" }
    end
  end

end
