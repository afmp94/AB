class NylasApi::Deltas::MessageDeltaParser

  attr_accessor :delta, :object_attributes

  def initialize(delta)
    @delta = delta
    @object_attributes = @delta.object_attributes
  end

  def parse
    if meets_requirements_to_save?
      save_delta_as_email_message
    end
  end

  private

  def meets_requirements_to_save?
    created_event? && required_message_params_present? && not_from_excluded_email_sender?
  end

  def created_event?
    delta.event == "create"
  end

  def not_from_excluded_email_sender?
    excluded_email_senders.none? { |sender| from_email.include?(sender) }
  end

  def excluded_email_senders
    %w(papertrailapp.com logentries.com)
  end

  def required_message_params_present?
    from_email.present? && object_attributes[:subject] && email_receiver_defined?
  end

  def email_receiver_defined?
    object_attributes[:to].present? || object_attributes[:bcc].present? ||
      object_attributes[:cc].present?
  end

  # rubocop:disable Metrics/AbcSize
  def save_delta_as_email_message
    if email_message_not_found_in_database?
      EmailMessage.create!(
        message_id: object_attributes[:id],
        thread_id: object_attributes[:thread_id],
        subject: object_attributes[:subject],
        snippet:  object_attributes[:snippet],
        received_at: Time.zone.at(object_attributes[:date]),
        to: object_attributes[:to],
        from_email: from_email,
        from_name: from_name,
        cc: object_attributes[:cc],
        bcc: object_attributes[:bcc],
        # body: object_attributes[:body],
        unread: object_attributes[:unread],
        user_id: user_who_owns_nylas_account&.id,
        account: user_who_owns_nylas_account&.nylas_connected_email_account,
        account_id: object_attributes[:account_id],
        to_email_addresses: parse_emails(object_attributes[:to])
      )
    end
  end
  # rubocop:enable Metrics/AbcSize

  def email_message_not_found_in_database?
    EmailMessage.find_by(message_id: object_attributes[:id]).blank?
  end

  def from_email
    if from_array_exists?
      object_attributes[:from][0][:email]
    end
  end

  def from_name
    if from_array_exists?
      object_attributes[:from][0][:name]
    end
  end

  def from_array_exists?
    object_attributes.present? && object_attributes[:from].present?
  end

  def parse_emails(to_array)
    to_array.map { |emails| emails[:email] }.map(&:downcase)
  end

  def user_who_owns_nylas_account
    User.find_by(nylas_account_id: object_attributes[:account_id])
  end

end
