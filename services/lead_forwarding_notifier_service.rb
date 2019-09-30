class LeadForwardingNotifierService

  attr_accessor :lead

  def initialize(lead)
    @lead = lead
  end

  def process
    begin
      send_email
      send_sms
      lead.refer!
    rescue => forwarding_error
      on_lead_notifier_error forwarding_error
    end
  end

  def send_email
    if lead&.created_by_user&.subscription.present?
      if lead.created_by_user.subscription.deactivated_on.nil?
        created_by_user = lead.created_by_user
        created_by_user.lead_setting.forward_to_group.find_each do |lead_group|
          lead_group.users.find_each do |group_user|
            next if group_user == created_by_user
            NewLeadProcessingMailer.delay.forward_new_lead_to_lead_group_user(lead, group_user)
            Util.log "Sending email: notify lead group of new incoming lead"
          end
        end
      end
    end
  end

  def send_sms
    if lead&.created_by_user&.subscription.present?
      if lead.created_by_user.subscription.deactivated_on.nil?
        created_by_user = lead.created_by_user if lead.created_by_user&.subscription&.deactivated_on.nil?
        created_by_user.lead_setting.forward_to_group.each do |lead_group|
          send_sms_to_creator_about_lead_forwarding created_by_user, lead_group
          lead_group.users.each do |group_user|
            next if group_user == created_by_user
            payload = sms_view_service.payload_for_forward_lead_to_group_user created_by_user: created_by_user,
                                                                              group_user: group_user,
                                                                              lead: lead
            SmsService.new.dispatch to: group_user.mobile_number, payload: payload
          end
        end
      end
    end
  end

  def send_sms_to_creator_about_lead_forwarding created_by_user, lead_group
    payload = sms_view_service.payload_to_creator_about_lead_forwarding lead_group: lead_group,
                                                                        lead: lead,
                                                                        created_by_user: created_by_user
    SmsService.new.dispatch to: created_by_user.mobile_number, payload: payload
  end

  def on_forwarding_error forwarding_error
    Util.log "Error in Lead Forwarding. #{forwarding_error}"
    lead.fail!
  end

  private

  def on_lead_notifier_error forwarding_error
    Util.log "Error in Notifying Lead. #{forwarding_error}"
    lead.fail!
  end

  def sms_view_service
    @sms_view_service ||= SmsViewService.new
  end

end
