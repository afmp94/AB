class UpdateLeadClientResponseService

  def update
    leads_awaiting_client_response = Lead.where(contacted_status: 2)
    leads_awaiting_client_response.each do |lead|
      if lead.first_email_attempted_id
        message = NylasMessage.find(lead.first_email_attempted_id)
        user = lead.user
        if message_needs_update(message)
          if user.nylas_token && user.subscription.present?
            if user.subscription.deactivated_on.nil?
              live_message = NylasApi::Message.new(token: user.nylas_token, id: message.nylas_message_id).fetch
              if live_message
                thread = NylasApi::Thread.new(token: user.nylas_token, id: live_message.thread_id).fetch
                thread.messages.each do |thread_message|
                  if lead_contact_has_email(lead)
                    match_email = lead.contact.primary_email_address.email
                    thread_message.from.each do |sender|
                      if sender["email"] == match_email
                        lead.contacted_status = "contacted"
                        lead.save
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def lead_contact_has_email(lead)
    lead&.contact&.primary_email_address && lead.contact.primary_email_address.email
  end

  def message_needs_update(message)
    if message.client_response_last_checked_at.nil?
      true
    else
      (Time.zone.now.to_i - message.client_response_last_checked_at.to_i) > 3600
    end
  end

end
