class LeadUnclaimedNotifierService

  attr_accessor :lead

  def initialize(lead)
    @lead = lead
  end

  def process
    send_email_notification_to_created_by_user
    send_sms_notification_to_created_by_user
  end

  private

  def send_email_notification_to_created_by_user
    return unless lead.created_by_user
    NewLeadProcessingMailer.delay.notify_about_lead_unclaimed(lead.created_by_user.id, lead.id)
  end

  def send_sms_notification_to_created_by_user
    return unless lead.created_by_user
    payload = "Lead #{lead.contact.full_name} was unclaimed."
    SmsService.new.delay.dispatch to: lead.created_by_user.mobile_number, payload: payload
  end

end
