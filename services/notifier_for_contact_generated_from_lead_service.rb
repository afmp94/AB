class NotifierForContactGeneratedFromLeadService

  attr_accessor :lead_email

  def initialize(lead_email)
    @lead_email = lead_email
  end

  def notify_about_success
    send_email
    send_sms
    send_push
  rescue => notifier_error
    on_error notifier_error
  end

  def auto_respond_to_lead
    user = lead.created_by_user
    lead_setting = user.lead_setting
    return unless lead_setting.email_auto_respond?
    leads_email = lead_email.contact.primary_email_address.email
    if lead_setting.send_auto_respond_email? leads_email
      send_auto_respond_email(lead_setting, leads_email, user)
      Util.log "Sending email: auto response to new lead"
    end
  end

  def notify_about_fail
    NewLeadProcessingMailer.delay.notify_about_lead_parsing_fail(lead_email)
  end

  # def forward_raw_email
  #   NewLeadProcessingMailer.delay.forward_raw_lead_email(lead_email)
  # end

  private

  def lead
    lead_email.lead
  end

  def send_push
    SmsMessages::SendAvailableLeadNotification.call(
      model: lead,
      receiver: lead.created_by_user
    )
  end

  def send_email
    if lead.created_by_user.lead_setting.new_lead_email_notification?
      NewLeadProcessingMailer.delay.notify_about_lead_parsing_success(
        lead,
        lead_email
      )
    end
    Util.log "Sending email: new lead parsed"
  end

  def send_sms
    user = lead.created_by_user
    return unless lead.created_by_user.lead_setting.new_lead_sms_notification?
    payload = sms_view_service.payload_for_new_lead_generated user: user, lead: lead
    SmsService.new.delay.dispatch to: user.mobile_number, payload: payload
  end

  def send_auto_respond_email(lead_setting, leads_email, user)
    NewLeadProcessingMailer.delay.auto_respond_to_new_lead(lead_setting, leads_email, user)
  end

  def on_error error
    Util.log "Error in Notifying Lead. #{error}"
    lead.fail!
  end

  def sms_view_service
    @sms_view_service ||= SmsViewService.new
  end

end
