class EmailInterceptorService

  def perform(emails)
    # For `test` mode, we already have configured our mandrill account for
    # `test` mode, so emails will not go the real users.

    if %(development staging).include? Rails.env
      Rails.application.secrets.intercept_and_forward_emails_to
    else
      emails
    end
  end

end
