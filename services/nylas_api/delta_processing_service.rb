class NylasApi::DeltaProcessingService

  attr_reader :type, :id, :account_id
  attr_accessor :user, :message, :delta

  def initialize(delta)
    @delta = delta
    @type = delta.type
    @id = delta.id
    @account_id = delta.account_id
  end

  def process
    case type
    when "message.created"
      Rails.logger.info "[NYLAS.webhooks] Processing message.create (#{id})..."
      process_created_message
    when "message.opened"
      Rails.logger.info "[NYLAS.webhooks] Processing message.opened (#{id})..."
      process_opened_message
    when "thread.replied"
      Rails.logger.info "[NYLAS.webhooks] Processing thread.replied (#{id})..."
      process_thread_replied
    when "message.link_clicked"
      Rails.logger.info "[NYLAS.webhooks] Processing message.link_clicked (#{id})..."
      process_message_link_clicked
    when *User::NYLAS_ACCOUNT_SYNC_STATUSES.keys
      process_account_sync
    end
  end

  private

  def process_opened_message
    if fetch_owner
      NylasApi::EmailTracking::OpenParser.new(delta).process
    else
      Rails.logger.info "[NYLAS.webhooks] Message owner not found"
    end
  end

  def process_created_message
    if fetch_owner
      create_email_message
    else
      Rails.logger.info "[NYLAS.webhooks] Message owner not found"
    end
  end

  def process_thread_replied
    if fetch_owner
      NylasApi::EmailTracking::ReplyParser.new(delta).process
    else
      Rails.logger.info "[NYLAS.webhooks] Message owner not found"
    end
  end

  def process_message_link_clicked
    if fetch_owner
      NylasApi::EmailTracking::LinkClickParser.new(delta).process
    else
      Rails.logger.info "[NYLAS.webhooks] Message owner not found"
    end
  end

  def process_account_sync
    if fetch_owner
      sync_account
    else
      Rails.logger.info "[NYLAS.webhooks] Owner not found"
    end
  end

  def fetch_owner
    @user = User.find_by(nylas_account_id: account_id)
  end

  def create_email_message
    if @message = nylas_message_object

      time_threshold = EmailMessage.minimum_time_threshold

      if formatted_date_received < time_threshold
        Rails.logger.info "[NYLAS.webhooks] Message is old to required minimum time threshhold"
      end

      if unique_message? && (formatted_date_received >= time_threshold)
        user.email_messages.create!(email_message_params)
        Rails.logger.info "[NYLAS.webhooks] Message created"

        if processeable_lead_email?
          ProcessLeadEmailFromNylasMessageService.new(message, user).process
        end
      else
        Rails.logger.info "[NYLAS.webhooks] Message not created (already exists)"
      end
    end
  end

  def sync_account
    user.update!(nylas_sync_status: User::NYLAS_ACCOUNT_SYNC_STATUSES[type])
    Rails.logger.info "[NYLAS.webhooks] Account sync status '#{type}' has set for user id #{user.id}"
  end

  def nylas_message_object
    NylasApi::Message.new(token: user.nylas_token, id: id).fetch
  end

  def unique_message?
    user.email_messages.find_by_message_id(message.id).nil?
  end

  def email_message_params
    {
      message_id: message.id,
      thread_id: message.thread_id,
      subject: remove_badstring(message.subject),
      snippet: remove_badstring(message.snippet),
      received_at: formatted_date_received,
      to: message.to,
      from_email: remove_badstring(from_email),
      from_name: remove_badstring(from_name),
      cc: message.cc,
      bcc: message.bcc,
      body: remove_badstring(message.body),
      unread: message.unread,
      account: user.nylas_connected_email_account
    }
  end

  def remove_badstring(data)
    data.delete("\u0000")
  end

  def formatted_date_received
    Time.zone.at(message.date)
  end

  def from_email
    message.from[0].email
  end

  def from_name
    message.from[0].name
  end

  def processeable_lead_email?
    !message_from_excluded_email? && message_from_a_lead_source?
  end

  def message_from_a_lead_source?
    (from_email =~ AppConstants::LEAD_SOURCES_REGEX) ||
      (message.body =~ AppConstants::LEAD_SOURCES_REGEX)
  end

  def message_from_excluded_email?
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
