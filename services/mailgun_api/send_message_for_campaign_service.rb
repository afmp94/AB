require "mailgun"

class MailgunApi::SendMessageForCampaignService

  attr_reader :mailgun_client, :mailgun_domain

  def initialize
    @mailgun_client = Mailgun::Client.new MAILGUN_API_KEY
    @mailgun_domain = MAILGUN_DOMAIN
  end

  def schedule_process(email_campaign, schedule_data)
    datetime = set_datetime_from(schedule_data)

    self.delay(run_at: datetime).process(email_campaign)
  end

  def process(email_campaign)
    owner      = email_campaign.user
    recipients = email_campaign.recipients

    results = recipients.map do |recipient|
      recipient_email = EmailAddress.where(owner_type: "Contact",
                                           owner_id: recipient.id,
                                           primary: true).pluck("email").first

      report = MarketReportMessage.new(
        contact_id: recipient.id,
        email_campaign_id: email_campaign.id,
      )

      content = generate_content_for(template(email_campaign),
                                     :@email_campaign => email_campaign,
                                     :@report => report,
                                     :@contact => recipient)

      # Intercept only for development, staging, and test modes.
      recipient_email = intercept_emails_for(recipient_email)
      recipient_email = recipient_email.first if recipient_email.is_a? Array
      result = build_message_and_send_to(email_campaign, content, recipient_email)

      if result
        create_campaign_message!(owner, recipient, email_campaign, result)
      end

      result
    end

    email_campaign.campaign_status = EmailCampaign.campaign_statuses[:sent]
    email_campaign.save!

    results.flatten
  rescue Mailgun::Error => e
    puts "A Mailgun error occurred: #{e.class} - #{e.message}"
    raise
  end

  def process_preview(email_campaign, recipient_emails, report)
    recipient_emails = recipient_emails.split(",").collect(&:strip)

    # Intercept only for development, staging, and test modes.
    recipient_emails = intercept_emails_for(recipient_emails)

    content = generate_content_for(template(email_campaign),
                                   :@email_campaign => email_campaign,
                                   :@report => report)

    build_message_and_send_to(email_campaign, content, recipient_emails)
  rescue Mailgun::Error => e
    puts "A Mailgun error occurred: #{e.class} - #{e.message}"
    raise
  end

  private

  def set_datetime_from(schedule_data)
    if schedule_data[:delivery_time] == EmailCampaign::DELIVERY_TIMES[:specific_time]
      specific_datetime = "#{schedule_data[:deliver_date]} #{schedule_data[:deliver_time]}"
      return Time.zone.parse(specific_datetime)
    else
      optimize_time("#{schedule_data[:deliver_date]}")
    end
  end

  def optimize_time(date)
    parsed_date = Time.zone.parse(date)

    datetime = case parsed_date.strftime("%A").downcase
               when "tuesday", "wednesday", "thursday"
                 "#{date} 10:00 AM"
               when "monday", "friday"
                 "#{date} 2:00 PM"
               else
                 "#{date} 8:00 AM"
               end

    Time.zone.parse(datetime)
  end

  def template(email_campaign)
    if email_campaign.campaign_type == EmailCampaign::CAMPAIGN_TYPES[:basic]
      "email_campaigns/preview_content_html"
    else
      "email_campaigns/preview_market_data"
    end
  end

  def campaign_attributes_valid?(campaign)
    campaign && campaign.title && campaign.name && campaign.content &&
      (campaign.contacts || campaign.groups)
  end

  def intercept_emails_for(recipient_emails)
    EmailInterceptorService.new.perform(recipient_emails)
  end

  def build_message_and_send_to(email_campaign, content, recipient_emails)
    owner = email_campaign.user

    mb_obj = Mailgun::BatchMessage.new(mailgun_client, mailgun_domain)

    mb_obj.subject(email_campaign.subject)
    mb_obj.body_html(content)

    owner_email = EmailCampaign::AlerternateDomainsService.new(owner.email).fetch || owner.email

    mb_obj.from(owner_email, "first" => owner.first_name, "last" => owner.last_name)

    mb_obj.instance_eval do
      # NOTE: Current version of `mailgun-ruby 1.1.0` has some issues with
      # `reply to` parameter setting through `add_recipient` method.
      # So this is a hack for temporary. Once we upgrade the `mailgun-ruby`
      # version then we need to remove this logic.
      @message["h:reply-to"] = owner.email
    end

    if recipient_emails.is_a? Array
      recipient_emails.each do |email|
        mb_obj.add_recipient(:to, email)
      end
    else
      mb_obj.add_recipient(:to, recipient_emails)
    end

    if Rails.env.test?
      mailgun_client.send_message(mailgun_domain, mb_obj).to_h
    else
      mailgun_client.send_message(mailgun_domain, mb_obj).to_h!
    end
  end

  def generate_content_for(template, locals)
    renderer = ApplicationController.renderer.new

    output = renderer.render(
      template: template,
      layout: false,
      locals: locals
    )

    premailer = Premailer.new(output, warn_level: Premailer::Warnings::SAFE,
                                      with_html_string: true)
    premailer.to_inline_css
  end

  def create_campaign_message!(owner, recipient, email_campaign, result)
    mailgun_id = clean_mailgun_id(result["id"])

    CampaignMessage.create!(user_id: owner.id,
                            contact_id: recipient.id,
                            email_campaign_id: email_campaign.id,
                            mailgun_id: mailgun_id)
  end

  def handle_campaign_message_event_for(item)
    event              = item["event"].downcase
    event_id           = item["id"]
    event_generated_at = Time.zone.at(item["timestamp"])
    message_id         = item["message"]["headers"]["message-id"]

    campaign_message = CampaignMessage.find_by(mailgun_id: message_id)

    if campaign_message.present?
      # Event id. It is guaranteed to be unique within a day. It can be used to
      # distinguish events that have already been retrieved when requests with
      # overlapping time ranges are made

      campaign_message_events = campaign_message.campaign_message_events

      if campaign_message_events.find_by(event_id: event_id, event_generated_at: event_generated_at).nil?
        campaign_message.campaign_message_events.create!(event_id: event_id,
                                                         event_type: event,
                                                         event_generated_at: event_generated_at)
      end
    end
  end

  def clean_mailgun_id(mailgun_id)
    mailgun_id.gsub("<", "").gsub(">", "")
  end

end
