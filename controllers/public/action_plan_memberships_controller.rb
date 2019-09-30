class Public::ActionPlanMembershipsController < ApplicationController

  skip_before_action :authenticate_user!

  def unsubscribe
    @action_plan_membership = ActionPlanMembership.find_by(subscription_token: params[:subscription_token])
    @action_plan = @action_plan_membership.action_plan

    if @action_plan_membership.state == "unsubscribed"
      redirect_to action_plan_path(@action_plan), notice: "You already have been unsubscribed!"
    else
      @action_plan.update_attributes(include_unsubscribe: true)
      @action_plan_membership.update_attributes(state: :unsubscribed)
      render layout: false
    end
  end

end
