class EndActionPlanOnReplyOption

  def process
    ActionPlan.end_on_reply.each do |action_plan|
      action_plan.action_plan_memberships.ready_to_execute.each do |action_plan_membership|
        user = action_plan.user
        nylas_messages(user).each do |msg|
          update_end_action_plan(action_plan_membership) if from_email(msg) == recipient_email(action_plan_membership)
        end
      end
    end
  end

  private

  def nylas_messages(user)
    account = NylasApi::Account.new(user.nylas_token).retrieve
    account&.messages || []
  end

  def recipient_email(action_plan_membership)
    action_plan_membership.contact.email
  end

  def from_email(msg)
    msg.from[0].email
  end

  def update_end_action_plan(action_plan_membership)
    action_plan_membership.update_attributes(end_action_plan: true)
  end

end
