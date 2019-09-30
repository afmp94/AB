class NylasLeadEmailParsingService

  def perform
    User.joins(:subscriptions).where(subscriptions: { deactivated_on: nil }).
      joins(:lead_setting).where.not(nylas_token: nil).
      where("lead_settings.parse_emails_with_inbox": true).find_each do |user|
      nylas_account = nylas_acount(user)
      messages_list = generate_recent_nylas_messages_list(nylas_account)
      messages_list.each do |message|
        if !matching_lead_emails_exist?(message.id, user.id)
          if !message_from_excluded_email?(message) && message_from_a_lead_source?(message)
            recipients = generate_message_recipients(message)
            lead_email = new_lead_email(recipients, message, user.id)
            if lead_email.save!
              process_email(lead_email)
            end
          end
        end
      end
    end
  end

  def nylas_acount(user)
    if token = user.nylas_token
      NylasApi::Account.new(token).retrieve
    end
  end

  def generate_recent_nylas_messages_list(nylas_account)
    twenty_minutes_ago       = Time.zone.now.to_i - 1200
    messages_list            = []
    threads_from_last_20_min = nylas_account.threads.where(last_message_after: twenty_minutes_ago)
    threads_from_last_20_min.each do |thread|
      thread.api.messages.where(thread_id: thread.id).each do |message|
        messages_list << message
      end
    end

    messages_list
  end

  def matching_lead_emails_exist?(message_id, user_id)
    LeadEmail.where(nylas_message_id: message_id, user_id: user_id).present?
  end

  def message_from_a_lead_source?(message)
    (message.from.first["email"] =~ AppConstants::LEAD_SOURCES_REGEX) || (message.body =~ AppConstants::LEAD_SOURCES_REGEX)
  end

  def generate_message_recipients(message)
    recipients = []

    if message.to.present?
      message.to.each do |recipient|
        recipients << recipient["email"]
      end
    end

    recipients.join(",")
  end

  def new_lead_email(recipients, message, user_id)
    LeadEmail.new.tap do |le|
      le.recipient = recipients
      le.to = recipients
      le.from = message.from.first["email"]
      le.subject = message.subject
      le.date = Time.at(message.date) if message.date
      le.text = generate_message_text(message)
      le.html = message.body
      le.nylas_message_id = message.id
      le.user_id = user_id
      le.headers = generate_message_text(message)
    end
  end

  def process_email(email)
    processing_service = LeadEmailProcessingService.new email
    processing_service.process
  end

  def generate_message_text(message)
    raw_message = message.raw.rfc2822 if message.raw
    if raw_message
      first_split = raw_message.partition("Content-Type: text/plain;")
      parsed_string = first_split[2]
      second_split = parsed_string.partition("Content-Type: text/html;")
      second_split[0]
    else
      ""
    end
  end

  def message_from_excluded_email?(message)
    from_email = message.from.first.class == Hash ? message.from.first["email"] : message.from.first.email
    from_excluded_email = false

    LeadEmail::EXCLUDED_EMAILS_FROM.each do |excluded_email|
      if from_email.include?(excluded_email)
        from_excluded_email = true
        break
      end
    end

    from_excluded_email
  end

end
