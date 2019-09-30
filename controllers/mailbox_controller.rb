class MailboxController < ActionController::Base

  def incoming
    Rails.logger.info "[EMAIL_PARSING] started processing message from mailgun. params: #{params.inspect}"
    Rails.logger.info ""
    Rails.logger.info ""

    @email = LeadEmail.new(email_params)

    Rails.logger.info "[EMAIL_PARSING] email_params: #{email_params.inspect}"
    Rails.logger.info ""
    Rails.logger.info ""

    if @email.save!
      LeadEmailProcessingJob.perform_later(@email.id)
      head :ok
    end
  end

  private

  def email_params
    result = Hash[
             [:recipient, :to, :from, :subject, :date, :text, :html, :headers, :token].
             zip(params.values_at(*%w(recipient To Sender Subject Date body-plain body-html message-headers token)))
             ]

    result[:subject] ||= params["subject"]
    result[:to]      ||= params["to"]
    result[:from]    ||= params["sender"]
    result[:date]    ||= params["date"]

    result
  end

end
