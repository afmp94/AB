class NylasService < Object

  attr_accessor :account

  def initialize(token)
    @token = token

    if @token
      @user    = User.find_by(nylas_token: @token)
      @account = NylasApi::Account.new(@token).retrieve
    end
  end

  def perform_delta_sync
    NylasApi::DeltaSyncService.new(@user, @account).sync
  end

  def send_email(contact, user, email_subject, email_body, lead=nil, nylas_message=nil)
    if params_are_all_present?(contact, user, email_subject, email_body)
      NylasApi::EmailSender.new(user).send(
        name: contact.name,
        email: contact.primary_email_address.email,
        subject: email_subject,
        body: email_body
      )

      set_lead_status_and_email_attempted_id(lead, nylas_message)
      true
    else
      false
    end
  end

  def send_email_for(to, cc, bcc, user, subject, body, lead=nil, nylas_message=nil)
    if params_are_all_present_for?(to, user, body)
      NylasApi::EmailSender.new(user).send_for(
        to: to,
        cc: cc,
        bcc: bcc,
        subject: subject,
        body: body
      )

      set_lead_status_and_email_attempted_id(lead, nylas_message)
      true
    else
      false
    end
  end

  def activity_stream_quick_email(email, user, email_subject, email_body, contact, nylas_message=nil, lead)
    if quick_email_params_are_present?(email, user, email_subject, email_body, contact)
      NylasApi::EmailSender.new(user).send(
        name: contact.name,
        email: email,
        subject: email_subject,
        body: email_body
      )

      set_lead_status_and_email_attempted_id(lead, nylas_message)
      true
    else
      false
    end
  end

  def reply_to_thread_participants(user, email_body, thread_id)
    NylasApi::EmailSender.new(user).send_thread_reply(thread_id: thread_id, body: email_body)
  end

  def reply_to_thread_message(contact, user, email_body, thread_id)
    if thread_params_are_all_present?(contact, user, email_body, thread_id)
      NylasApi::EmailSender.new(user).send_thread_message_reply(thread_id: thread_id, body: email_body)
    else
      false
    end
  end

  def forward_email(to, user, thread, message)
    NylasApi::EmailSender.new(user).forward_email(to: to, thread: thread,
                                                  message: message)
  end

  private

  def email_is_valid?(email)
    ValidateEmail.valid?(email)
  end

  def set_lead_status_and_email_attempted_id(lead, nylas_message=nil)
    if lead && lead.contacted_status == 0
      lead.contacted_status = 2
      lead.first_email_attempted_id = nylas_message.id if nylas_message
      lead.save!
    end
  end

  def thread_params_are_all_present?(contact, user, email_body, thread_id)
    (contact && contact.primary_email_address && contact.primary_email_address.email) &&
      (user && user.nylas_token && user.email) && email_body && thread_id
  end

  def thread_participant_params_are_all_present?(user, email_body, thread_id)
    (user && user.nylas_token) && email_body && thread_id
  end

  def params_are_all_present?(contact, user, email_subject, email_body)
    (contact && contact.primary_email_address && contact.primary_email_address.email) &&
      (user && user.nylas_token) && (email_subject && email_body)
  end

  def params_are_all_present_for?(to, user, email_body)
    to.present? && (user && user.nylas_token) && email_body.present?
  end

  def quick_email_params_are_present?(email, user, email_subject, email_body, contact)
    email && user && @token && email_subject && email_body && contact
  end

end
