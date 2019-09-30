class SmsViewService

  def payload_for_new_lead_generated(options)
    ApplicationController.render("sms/new_lead_generated", locals: options)
  end

  def payload_for_new_public_lead(options)
    ApplicationController.render("sms/new_public_lead_generated", locals: options)
  end

  def payload_for_forward_lead_to_group_user(options)
    ApplicationController.render("sms/forward_lead_to_group_user", locals: options)
  end

  def payload_to_creator_about_lead_forwarding(options)
    ApplicationController.render("sms/lead_forwarded_to_group", locals: options)
  end

end
