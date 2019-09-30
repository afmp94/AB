class GetUserOrContactFromMessageService

  def self.process(message, user, contact)
    emails = message.from.map { |h| h.class == Hash ? h["email"] : h.email }

    if user.present? && emails.include?(user.nylas_connected_email_account)
      return user
    elsif (contact.email_addresses.pluck(:email) & emails).present?
      return contact
    end
  end

end
