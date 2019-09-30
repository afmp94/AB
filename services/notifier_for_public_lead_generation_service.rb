class NotifierForPublicLeadGenerationService

  attr_accessor :lead

  def initialize(lead)
    @lead = lead
  end

  def notify
    begin
      send_email
      send_sms
    rescue => notifier_error
      on_error notifier_error
    end
  end

  private

  def send_email
    NewLeadProcessingMailer.delay.notify_about_new_public_lead(lead) if
    lead.created_by_user.lead_setting.new_lead_email_notification?
  end

  def send_sms
    user = lead.created_by_user
    return unless user.lead_setting.new_lead_sms_notification?
    payload = sms_view_service.payload_for_new_lead_generated user: user, lead: lead
    SmsService.new.delay.dispatch to: user.mobile_number, payload: payload
  end

  def on_error error
    Rails.logger.warn "Error in Notifying Lead. #{error}"
    lead.fail!
  end

  def sms_view_service
    @sms_view_service ||= SmsViewService.new
  end

end
