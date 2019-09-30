class ManualLeadForwardingService

  attr_accessor :lead
  attr_accessor :lead_group

  def initialize(lead, lead_group)
    @lead_group = lead_group
    @lead = lead
  end

  def process
    begin
      send_email
      send_sms
    rescue => forwarding_error
      on_forwarding_error forwarding_error
    end
  end

  def send_email
    created_by_user = lead.created_by_user
    lead_group.users.find_each do |group_user|
      next if group_user == created_by_user
      NewLeadProcessingMailer.delay.forward_new_lead_to_lead_group_user(lead, group_user)
    end
  end

  def send_sms
    created_by_user = lead.created_by_user
    lead_group.users.find_each do |group_user|
      next if group_user == created_by_user
      payload = sms_view_service.payload_for_forward_lead_to_group_user created_by_user: created_by_user,
                                                                        group_user: group_user,
                                                                        lead: lead
      SmsService.new.dispatch to: group_user.mobile_number, payload: payload
    end
  end

  def on_forwarding_error forwarding_error
    Rails.logger.error "Error in Lead Forwarding. #{forwarding_error}"
    lead.fail!
  end

  def sms_view_service
    @sms_view_service ||= SmsViewService.new
  end

end
