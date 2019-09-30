class ActionPlansController < ApplicationController

  before_action :set_action_plan, only: %i(edit update show destroy)
  before_action :redirect_with_message, only: %i(edit update show destroy)
  before_action :update_steps_order, only: %i(update)

  def index
    @action_plans = current_user.action_plans
  end

  def new
    @action_plan = ActionPlan.new
    @action_plan.action_plan_steps.build
  end

  def create
    @action_plan = current_user.action_plans.build(action_plan_params)
    update_steps_order
    if @action_plan.save
      flash[:notice] = "Action Plan has been created successfully"
      redirect_index
    else
      flash[:error] = @action_plan.errors.full_messages.join(",")
      redirect_to new_action_plan_path
    end
  end

  def edit
    @action_plan.action_plan_steps.build if @action_plan.action_plan_steps.blank?
  end

  def update
    if @action_plan.update(action_plan_params)
      flash[:notice] = "Action Plan has been updated successfully"
      redirect_index
    else
      flash[:error] = @action_plan.errors.full_messages.join(",")
      redirect_to edit_action_plan_path(@action_plan)
    end
  end

  def show
    @action_plan_memberships = @action_plan.action_plan_memberships
  end

  def destroy
    if @action_plan.destroy
      flash[:notice] = "action_plan has been deleted successfully"
      redirect_index
    else
      flash[:error] = @action_plan.errors.full_messages.join(",")
      redirect_to action_plan_path(@action_plan)
    end
  end

  private

  def action_plan_params
    params.require(:action_plan).permit(
      :name,
      :purpose,
      :include_unsubscribe,
      :end_on_reply,
      :only_active_action_plan_allowed,
      :allow_repeat_subscribers,
      action_plan_steps_attributes: [
        :id,
        :delay_in_days,
        :email_template_id,
        :notify_if_opened,
        :order,
        :require_approval,
        :reset_delay_if_interaction,
        :send_time,
        :step_type,
        :track,
        :_destroy
      ]
    )
  end

  def redirect_index
    redirect_to action_plans_path
  end

  def set_action_plan
    @action_plan = current_user.action_plans.find_by(id: params[:id])
  end

  def redirect_with_message
    redirect_to action_plans_path, notice: "You are not authorized" if @action_plan.blank?
  end

  def update_steps_order
    if @action_plan.new_record?
      @action_plan.action_plan_steps.each_with_index do |action_plan_step, index|
        action_plan_step.order = index + 1
      end
    else
      steps_index = 1
      action_plan_steps_params = action_plan_params[:action_plan_steps_attributes] || []

      action_plan_steps_params.each do |_key, attributes|
        if attributes["_destroy"] != "1"
          attributes["order"] = steps_index.to_s
          steps_index = steps_index + 1
        end
      end
    end
  end

end
