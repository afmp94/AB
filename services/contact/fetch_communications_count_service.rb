class Contact::FetchCommunicationsCountService

  attr_reader :contact

  def initialize(contact)
    @contact = contact
  end

  def process
    user = contact.user

    return nil if user.nylas_token.blank? || user.nylas_connected_email_account.blank?

    contact.update(
      total_received_messages_count: contact.received_email_messages_total_count_from_nylas,
      total_sent_messages_count: contact.sent_email_messages_total_count_from_nylas,
      total_received_messages_count_in_past_year: contact.received_email_messages_total_count_from_nylas_in_past_year,
      total_sent_messages_count_in_past_year: contact.sent_email_messages_total_count_from_nylas_in_past_year,
    )
  end

end
