module ProfilesHelper

  def email_label(user)
    str = "Email"

    if user.confirmed?
      str << " (<span style='color:green'>Confirmed</span>)"
    else
      str << " (<span style='color:red'>Not confirmed</span> | "
      str << link_to("Resend confirmation", send_email_confirmation_notification_path)
      str << ")"
    end

    str
  end

end
