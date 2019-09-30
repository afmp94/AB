class NylasApi::EmailSender

  def initialize(user)
    @user = user
    @token = @user.nylas_token
    @account = NylasApi::Account.new(@token).retrieve
  end

  def send(name:, email:, subject:, body:)
    if email_is_valid?(email)
      response = @account.send!(
        to: [{ name: name, email: email }],
        subject: subject,
        body: body,
        tracking: { opens: true, links: true, thread_replies: true }
      )

      Rails.logger.info "Response[draft.send!]: #{response}"
      response
    end
  end

  def send_for(to:, cc:, bcc:, subject:, body:)
    response = @account.send!(
      to: to,
      cc: cc,
      bcc: bcc,
      subject: subject,
      body: body,
      tracking: { opens: true, links: true, thread_replies: true }
    )

    Rails.logger.info "Response[draft.send!]: #{response}"
    true
  end

  # default class only accepts nylas email addresss as to
  def send_thread_reply(thread_id:, body:)
    thread = NylasApi::Thread.new(token: @token, id: thread_id)
    if thread.fetch
      participants = thread.participants
      participants = participants.reject { |x| [@user.email, @user.nylas_connected_email_account].include?(x.email) }
      recipient = participants.collect { |recp| { name: recp.name.presence || recp.email, email: recp.email } }
      message = reply_to_message(thread)

      build_and_send_thread_reply(
        reply_to_message_id: message.id,
        thread_id: thread_id,
        to: recipient,
        body: body
      )
    end
  end

  def reply_to_message(thread)
    thread.fetch.api.messages.where(thread_id: thread.id).first
  end

  def send_thread_message_reply(thread_id:, body:)
    thread = NylasApi::Thread.new(token: @token, id: thread_id)
    if thread.fetch
      if message = thread.fetch.api.messages.where(thread_id: thread.id).first
        recipient = determine_message_recipient(message)
        build_and_send_thread_reply(
          reply_to_message_id: message.id,
          thread_id: thread_id,
          to: recipient,
          body: body
        )
      end
    end
  end

  def forward_email(to:, thread:, message:)
    draft = @account.drafts.new(
      thread_id:  thread.id,
      to: to,
      subject: "Fwd: #{thread.subject}",
      body: message.body
    )
    if message.api.files.present?
      message.api.files.each do |file|
        attach(draft, file)
      end
    end

    response = draft.send!
    Rails.logger.info "Response[draft.send!]: #{response}"
    true
  end

  def attach(draft, file)
    Util.nylas_response("post",
                        "https://api.nylas.com/drafts",
                        draft.api.client.access_token,
                        "{\"file_ids\":[\"#{file.id}\"]}")
  end

  private

  def email_is_valid?(email)
    ValidateEmail.valid?(email)
  end

  def build_and_send_thread_reply(options={})
    response = @account.send!(
      reply_to_message_id: options[:reply_to_message_id],
      to: options[:to],
      body: options[:body],
      tracking: { opens: true, links: true, thread_replies: true }
    )

    Rails.logger.info "Response[draft.send!]: #{response}"
    true
  end

  def determine_message_recipient(message)
    if [@user.email, @user.nylas_connected_email_account].include?(message.from[0].email)
      message.to
    else
      message.from
    end
  end

end
