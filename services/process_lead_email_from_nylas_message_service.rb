require "charlock_holmes"

class ProcessLeadEmailFromNylasMessageService

  attr_reader :nylas_message, :user

  def initialize(nylas_message, user)
    @nylas_message = nylas_message
    @user = user
  end

  def process
    lead_email = LeadEmail.new(lead_email_params)
    if lead_email.save!
      LeadEmailProcessingJob.perform_later(lead_email.id)
    end
    Rails.logger.info "Lead email got processed for Nylas message id '#{nylas_message.id}'"
  end

  def lead_email_params
    result = {}

    result[:recipient]           = get_to_recipients
    result[:to]                  = get_to_recipients
    result[:from]                = transcode(from_email)
    result[:subject]             = transcode(nylas_message.subject)
    result[:date]                = Time.at(nylas_message.date) if nylas_message.date
    result[:text]                = transcode(generate_nylas_message_text)
    result[:html]                = transcode(nylas_message.body)
    # result[:headers]            = # If we need this then we might need to check
    # Nylas doc for how we can get header from Nylas response
    result[:token]               = user.nylas_token # token
    result[:nylas_message_id]    = nylas_message.id
    result[:user_id]             = user.id # user_id of current acccount may be

    result
  end

  def generate_nylas_message_text
    require "httparty"
    require "mail"

    raw_message_body = HTTParty.get(
      "https://api.nylas.com/messages/#{nylas_message.id}",
      headers: {
        "Accept": "message\/rfc822",
        "Authorization": user.nylas_token
      }
    )

    body = Mail.new(raw_message_body.to_s).body
    Rails.logger.info "[ProcessLeadEmail..] encoding: #{body.encoding}"
    if body.encoding == "7bit"
      body.raw_source || ""
    else
      body.to_s || ""
    end
  end

  def get_to_recipients
    nylas_message.to[0].email
  end

  def from_email
    nylas_message.from[0].email
  end

  def transcode(content)
    detection = CharlockHolmes::EncodingDetector.detect(content)
    CharlockHolmes::Converter.convert content, detection[:encoding], "UTF-8"
  end

end
