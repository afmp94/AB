class LeadClaimedNotifierService

  attr_accessor :lead
  attr_accessor :notified_to

  def initialize(lead)
    @lead = lead
    @notified_to = []
  end

  def process
    begin
      send_sms_to_owner
      send_sms_to_created_by_user
      send_sms_to_lead_forward_users
      send_sms_to_lead_broadcast_users
    rescue => notifier_error
      on_claim_notifier_error notifier_error
    end
  end

  def send_sms_to_owner
    payload = "Lead Claimed! #{lead.contact.full_name}"
    SmsService.new.dispatch to: lead.user.mobile_number, payload: payload
    mark_as_notified lead.user.email
  end

  def send_sms_to_created_by_user
    return if notified_user_with_email? lead.created_by_user.email
    payload = "Claimed by #{lead.user.full_name}: #{lead.contact.full_name}"
    SmsService.new.dispatch to: lead.created_by_user.mobile_number, payload: payload if lead.user.lead_setting.lead_claimed_sms_notification?
    mark_as_notified lead.created_by_user.email
  end

  def send_sms_to_lead_forward_users
    return unless lead.referred?
    user = lead.created_by_user
    payload = lead_not_available_payload
    user.lead_setting.forward_to_group.find_each do |lead_group|
      lead_group.users.find_each do |group_user|
        next unless notified_user_with_email? group_user.email
        SmsService.new.dispatch to: group_user.mobile_number, payload: payload
        mark_as_notified group_user.email
      end
    end
  end

  def send_sms_to_lead_broadcast_users
    return unless (lead.broadcast? || lead.re_broadcast?)
    created_by_user = lead.created_by_user
    payload = lead_not_available_payload
    created_by_user.lead_setting.broadcast_to_group.find_each do |lead_group|
      lead_group.users.find_each do |group_user|
        next if notified_user_with_email? group_user.email
        SmsService.new.dispatch to: group_user.mobile_number, payload: payload
        mark_as_notified group_user.email
      end
    end
  end

  def notified_user_with_email? email
    notified_to.include? email
  end

  def lead_not_available_payload
    "Lead No Longer Available: #{lead.contact.full_name}"
  end

  def mark_as_notified email
    notified_to << email
  end

  def on_claim_notifier_error error
    Rails.logger.error "Error in Notifying about lead claiming #{error}"
  end

end
