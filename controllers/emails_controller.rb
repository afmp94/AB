class EmailsController < ApplicationController

  def show
    render
  end

  def display_thread
    @contact = Contact.find(params["contact_id"])
    @original_url = params["url"]
    @thread = NylasApi::Thread.new(token: current_user.nylas_token, id: params["thread_id"]).fetch
    @messages = @thread.api.messages
    @message_id = params["message_id"]
    @trail = params["trail"]
  end

  def download_file
    nylas_file = NylasApi::File.new(token: current_user.nylas_token, id: params["file_id"])
    file = nylas_file.fetch
    send_data file_download(file), filename: file.filename, type: file.content_type
  end

  def send_email_through_nylasapp
    user = current_user
    thread_id = params[:thread_id]
    email_body = params[:body][:email_body]
    contact_id = params[:contact_id]
    contact = Contact.find(contact_id)
    api_service = NylasService.new(user.nylas_token)
    trail = params[:trail]

    if params[:reply_all]
      if api_service.reply_to_thread_participants(user, email_body, thread_id)
        redirect_to(
          controller: "emails",
          action: "display_thread",
          thread_id: thread_id,
          contact_id: contact_id,
          trail: trail,
          notice: "Email successfully sent to participants"
        )
      else
        redirect_to(
          controller: "emails",
          action: "display_thread",
          thread_id: thread_id,
          contact_id: contact_id,
          trail: trail,
          notice: "Sorry there was an error sending the email, please try again"
        )
      end
    elsif api_service.reply_to_thread_message(contact, user, email_body, thread_id)
      redirect_to(
        controller: "emails",
        action: "display_thread",
        thread_id: thread_id,
        contact_id: contact_id,
        trail: trail,
        notice: "Email successfully sent!"
      )
    else
      redirect_to(
        controller: "emails",
        action: "display_thread",
        thread_id: thread_id,
        contact_id: contact_id,
        trail: trail,
        notice: "Sorry there was an error sending the email, please try again"
      )
    end
  end

  def open_modal_for_forwarding_email
    @contact = Contact.find(params[:contact_id])
    @original_url = params["url"]
    @thread = NylasApi::Thread.new(token: current_user.nylas_token, id: params["thread_id"]).fetch
    @message = @thread.api.messages.find(params[:message_id])
  end

  def forward_email_through_nylasapp
    @contact     = Contact.find(params[:contact_id])
    @to          = params[:to].split(",").map(&:strip)
    @email_error = false
    @success     = false

    @to.map! do |email|
      if !!!(email =~ AppConstants::EMAIL_REGEX)
        @email_error = true
        break
      end
      { name: "", email: email }
    end

    if !@email_error
      @thread = NylasApi::Thread.new(token: current_user.nylas_token,
                                     id: params["thread_id"]).fetch

      @message = @thread.api.messages.find(params[:message_id])
      api_service = NylasService.new(current_user.nylas_token)
      @success = api_service.forward_email(@to, current_user, @thread, @message)
    end

    if @success
      @path = display_thread_path(contact_id: @contact.id, thread_id: @thread.id,
                                  message_id: @message.id)

      flash[:notice] = "Your email was successfully sent!"
    else
      render
    end
  end

  def send_lead_email_through_nylasapp
    contact     = Contact.find(params[:contact_id])
    lead        = Lead.find(params[:lead_id])
    success     = false
    msg_builder = MessageBuilderService.new(build_message_builder_options).process

    if !msg_builder.has_email_errors?
      email_body = Views::SimpleFormatService.convert(msg_builder.body)
      email_body = Views::SetEmailSignatureToBodyService.new(email_body, current_user).process

      result             = add_tracking_to_email_body(email_body, contact, current_user, lead)
      tracked_email_body = result[0]
      nylas_message      = result[1]

      api_service = NylasService.new(current_user.nylas_token)
      success     = api_service.send_email_for(msg_builder.to, msg_builder.cc, msg_builder.bcc, current_user,
                                               msg_builder.subject, tracked_email_body, lead, nylas_message)

    end

    if success
      redirect_to lead, notice: "Your email was successfully sent!"
    else
      redirect_to lead, alert: "Sorry there was a problem sending your \
                                email (you may not have yet \
                                connected your email address or your contacts \
                                email may not be valid) \
                                Please verify and try again."
    end
  end

  def send_contact_email_through_nylasapp
    contact     = Contact.find(params[:contact_id])
    success     = false
    msg_builder = MessageBuilderService.new(build_message_builder_options).process

    if !msg_builder.has_email_errors?
      user               = current_user
      email_body         = Views::SimpleFormatService.convert(msg_builder.body)
      email_body         = Views::SetEmailSignatureToBodyService.new(email_body, current_user).process

      api_service = NylasService.new(user.nylas_token)
      success = api_service.send_email_for(
        msg_builder.to,
        msg_builder.cc,
        msg_builder.bcc,
        user,
        msg_builder.subject,
        email_body,
        nil,
        nil
      )
    end

    if success
      redirect_to contact, notice: "Your email was successfully sent!"
    else
      redirect_to contact, alert: "Sorry there was a problem sending your \
                                   email (you may not have yet \
                                   connected your email address or your contacts \
                                   email may not be valid) \
                                   Please verify and try again."
    end
  end

  def activity_stream_quick_email
    contact = Contact.find(params[:contact_id])
    lead = Lead.find(params[:lead_id])
    email_subject = params[:subject]
    email_body = Views::SetEmailSignatureToBodyService.new(params[:body], current_user).process
    email = params[:recipient]
    user = current_user

    result = add_tracking_to_email_body(email_body, contact, user)
    tracked_email_body = result[0]
    nylas_message = result[1]

    api_service = NylasService.new(user.nylas_token)
    if api_service.activity_stream_quick_email(
      email,
      user,
      email_subject,
      tracked_email_body,
      contact,
      nylas_message,
      lead
    )
      respond_to do |format|
        message = "success"
        format.json { render json: message }
      end
    else
      respond_to do |format|
        message = "fail"
        format.json { render json: message }
      end
    end
  end

  def mark_thread_as_read
    begin
      redirect_url = URI.parse(params[:url]).path
    rescue URI::InvalidURIError
      redirect_url = root_path
    end

    if NylasApi::Thread.new(token: current_user.nylas_token, id: params[:thread_id]).mark_as_read
      redirect_to redirect_url, notice: "Thread has been marked as read!"
    else
      redirect_to redirect_url, notice: "Sorry there was an error, please try again"
    end
  end

  def destroy_email_thread
    url = params[:url]
    begin
      redirect_url = URI.parse(url).path
    rescue URI::InvalidURIError
      redirect_url = root_path
    end
    thread_id = params[:thread_id]
    token = current_user.nylas_token
    api_service = NylasService.new(token)
    if api_service.destroy_email_thread(thread_id)
      redirect_to redirect_url, notice: "Thread successfully destroyed"
    else
      redirect_to redirect_url, notice: "Sorry there was an error destroying your thread, please try again"
    end
  end

  private

  def add_tracking_to_email_body(email_body, contact, user, lead=nil)
    if contact.has_a_valid_primary_email_address?
      options = { user_id: user.id, contact_id: contact.id, opened: false, clicked: false }

      options[:lead_id] = lead.id if lead.present?

      nylas_message = NylasMessage.new(options).tap do |message|
        message.sent_to_email_address = contact.primary_email_address.email
        message.opens_tracking_id = RandomIdGenerator.new.id(25)
        message.save
      end

      [email_body, nylas_message]
    else
      [email_body, nil] # no change
    end
  end

  def build_message_builder_options
    options = {}
    contact           = Contact.find(params[:contact_id])

    options[:to]      = params[:to_recipients].presence || contact.email
    options[:cc]      = params[:cc_recipients] if params[:cc_recipients].present?
    options[:bcc]     = params[:bcc_recipients] if params[:bcc_recipients].present?
    options[:subject] = params[:subject][:email_subject] if params[:subject][:email_subject].present?
    options[:body]    = params[:body][:email_body] if params[:body][:email_body].present?
    options[:user]    = current_user

    options
  end

  def file_download(file)
    Util.nylas_response("get", "https://api.nylas.com/files/#{file.id}/download", file.api.client.access_token)
  end

end
