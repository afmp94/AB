class LeadFollowupReminderService

  def notify
    leads = Lead.lead_status
    leads.find_each do |lead|
      Util.log "Lead Follow Up Service for lead_#{lead.id}"
      if lead_claimed_and_not_yet_contacted?(lead)
        Util.log "lead_#{lead.id} was claimed but not contacted"
        if lead.lead_followup_reminder_time
          Util.log "Lead has followup time set"
          if notification_interval_passed_since_lead_claimed?(lead)
            Util.log "Notifying"
            if lead&.created_by_user&.subscription.present? && lead.created_by_user.subscription.deactivated_on.nil?
              send_reminder(lead)
            end
          else
            Util.log "Notication interval has not passed"
          end
        else
          Util.log "No reminder time set. Setting time now."
          lead.lead_followup_reminder_time = Time.zone.now
          lead.save!
        end
      end
    end
  end

  def lead_claimed_and_not_yet_contacted?(lead)
    ((lead.contacted_status == 0) && (lead.user_id) && (lead.state == "claimed") && (lead.lead_followup_reminder_attempted == false))
  end

  def notification_interval_passed_since_lead_claimed?(lead)
    user = User.find(lead.user_id)
    time_interval = user.lead_setting.notification_time_interval * 3600
    (((lead.lead_followup_reminder_time.to_i - Time.zone.now.to_i) >= time_interval) && (User.find(lead.user_id).mobile_number if User.find(lead.user_id) ) && (User.find(lead.user_id).email if User.find(lead.user_id)))
  end

  def send_reminder(lead)
    user = User.find(lead.user_id)
    lead_id = lead.id
    payload = "The lead #{lead.name} has not yet been contacted => #{link_to "Click here to see", lead}"
    if sms_permission?(user)
      SmsService.new.dispatch to: user.mobile_number, payload: payload, user_id: user.id
    end
    if email_permission?(user)
      Mailer.lead_followup_reminder(user.id, lead_id).deliver_now
    end
    lead.lead_followup_reminder_attempted = true
    lead.save!
    return test_deliveries_counter
  end

  def sms_permission?(user)
    user.lead_setting.followup_lead_sms_permission
  end

  def email_permission?(user)
    user.lead_setting.followup_lead_email_permission
  end

end
