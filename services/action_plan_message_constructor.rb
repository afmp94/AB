class ActionPlanMessageConstructor

  def initialize(message, contact, action_plan_membership)
    @message = message
    @contact = contact
    @action_plan_membership = action_plan_membership
    @action_plan = @action_plan_membership.action_plan
  end

  def construct
    dynamic_message = EmailTemplates::DynamicFieldsPopulator.new(@message.to_s, @contact).populate
    unsubscribe_path = Rails.application.routes.url_helpers.public_unsubscribe_action_plan_membership_path(
      subscription_token:
      @action_plan_membership.subscription_token
    )
    url_with_port = Rails.application.secrets.url_with_port

    if @action_plan.include_unsubscribe == true && !dynamic_message.include?("/unsubscribe?")
      dynamic_message = dynamic_message + "<br> <a href=#{url_with_port.gsub('localhost', '0.0.0.0')}" \
        "#{unsubscribe_path}>" \
        " Unsubscribe </a>"
    end
    dynamic_message
  end

end
