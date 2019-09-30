class LeadBroadcastingNotifierService

  attr_accessor :lead
  attr_accessor :notified_to

  def initialize(lead)
    @lead = lead
    @notified_to = []
    init_notified_to_users_list
  end

  def process
    begin
      send_email
      send_sms
      lead.set_broadcast_state!
    rescue => forwarding_error
      on_forwarding_error forwarding_error
    end
  end

  def send_email
    if lead&.created_by_user&.subscription.present? && lead.created_by_user.subscription.deactivated_on.nil?
      user = lead.created_by_user
      user.lead_setting.broadcast_to_group.find_each do |lead_group|
        lead_group.users.find_each do |group_user|
          next unless notify_user? group_user.email
          NewLeadProcessingMailer.delay.broadcast_new_lead_to_lead_group_user(lead, group_user)
        end
      end
    end
  end

  def send_sms
    if lead&.created_by_user&.subscription.present? && lead.created_by_user.subscription.deactivated_on.nil?
      created_by_user = lead.created_by_user if lead.created_by_user&.subscription&.deactivated_on.nil?
      created_by_user.lead_setting.broadcast_to_group.each do |lead_group|
        send_sms_to_creator_about_lead_forwarding created_by_user, lead_group
        lead_group.users.find_each do |group_user|
          next unless notify_user? group_user.email
          send_sms_to_group_user created_by_user, group_user
          send_push(group_user)
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

  def send_sms_to_group_user created_by_user, group_user
    payload = sms_view_service.payload_for_forward_lead_to_group_user created_by_user: created_by_user,
                                                                      group_user: group_user,
                                                                      lead: lead
    SmsService.new.dispatch to: group_user.mobile_number, payload: payload
  end

  private

  def send_push(receiver)
    SmsMessages::SendAvailableLeadNotification.call(
      model: lead,
      receiver: receiver
    )
  end

  def on_forwarding_error forwarding_error
    Rails.logger.error "Error in Lead Broadcasting. #{forwarding_error}"
    lead.fail!
  end

  def init_notified_to_users_list
    notified_to = []
    notified_to << lead.created_by_user.email if lead.created_by_user&.subscription&.deactivated_on.nil?
    if lead.referred?
      lead.created_by_user.lead_setting.forward_to_group.find_each do |group|
        group.users.find_each do |group_user|
          notified_to << group_user.email
        end
      end
    end
    @notified_to = notified_to.uniq
  end

  def notify_user? email
    !(@notified_to.present? &&
        @notified_to.include?(email))
  end

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def sms_view_service
    @sms_view_service ||= SmsViewService.new
  end

end
