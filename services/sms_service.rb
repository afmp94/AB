class SmsService

  def dispatch(options)
    options.reverse_merge! from: Rails.application.secrets.twilio[:from_number]

    from = options.fetch(:from).to_s.strip
    to = options.fetch(:to).to_s.strip
    payload = options.fetch(:payload).to_s.strip
    user_id = options.fetch(:user_id, nil).to_s.strip
    # quiet_hours = options.fetch(:quiet_hours).to_s.strip

    if user_id.present?
      user = User.find(user_id)
      in_quiet_hours = user.in_quiet_hours?
    else
      in_quiet_hours = false
    end

    if in_quiet_hours
      return false
    else
      if to.length < 10
        Rails.logger.error "SmsService: to value #{to} is an invalid phone number!"
        Rails.logger.error "SmsService: the message will not be sent"
        return false
      end

      if payload.blank?
        Rails.logger.error "SmsService: payload can't be blank"
        Rails.logger.error "SmsService: the message will not be sent"
        return false
      end

      from = "+1#{from}"
      to =  "+1#{to}"

      options = { from: from, to: to, body: payload }
      Rails.logger.info "[#{self.class.name}] options: #{options.inspect}"

      send_sms options
      return true
    end
  end

  private

  def send_sms(options)
    result = twilio_client.account.sms.messages.create options
    save_result_to_api_response_model(result)
  end

  def twilio_client
    Twilio::REST::Client.new TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN
  end

  def save_result_to_api_response_model(result)
    Util.log "RESULT ==> #{result}"
    Util.log "RESULT INSPECT ==> #{result.inspect}"
    response_model = ApiResponse.new
    response_model.api_type = "twilio"
    response_model.api_called_at = Time.zone.now
    response_model.status = result.status
    response_model.message = "A message was just delivered via Twilio to the number: #{result.to} ,
                             the current status of the message is : #{result.status}"[0, 250] # avoid pg string error
    response_model.save!
  end

end
