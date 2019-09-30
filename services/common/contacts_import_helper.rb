module Common

  module ContactsImportHelper

    def set_contact_mandatory_fields(new_contact, user)
      new_contact.user_id = user.id
      new_contact.created_by_user_id = user.id

      yield(new_contact) if block_given?

      new_contact
    end

    def set_other_fields(new_contact)
      new_contact.set_name if new_contact.name.blank?
      new_contact.set_salutations
      new_contact.set_avatar_background_color

      yield(new_contact) if block_given?

      new_contact
    end

    def set_primary_to_email_and_phone(new_contact)
      set_primary_email(new_contact)
      set_primary_phone(new_contact)

      new_contact
    end

    def set_primary_email(new_contact)
      email_address = new_contact.email_addresses.select(&:primary)&.first

      if email_address.blank?
        email_address = new_contact.email_addresses.first

        if email_address.present?
          email_address.primary = true
          new_contact.email = email_address.email
        end
      else
        new_contact.email = email_address.email
      end
    end

    def set_primary_phone(new_contact)
      phone_number = new_contact.phone_numbers.select(&:primary)&.first

      if phone_number.blank?
        phone_number = new_contact.phone_numbers.first

        if phone_number.present?
          phone_number.primary = true
          new_contact.phone_number = phone_number.number
        end
      else
        new_contact.phone_number = phone_number.number
      end
    end

    def handle_validations(new_contact)
      errors = []

      if new_contact.first_name.blank? && new_contact.last_name.blank?
        if new_contact.email_blank? && new_contact.phone_blank?
          errors << "Either first name, last name, email addres or phone number should be present"
        end
      end

      new_contact.email_addresses.each do |email_address|
        if !!!(email_address.email =~ AppConstants::EMAIL_REGEX)
          errors << "#{email_address.email} is not valid email address"
        end
      end

      raise errors.to_sentence if errors.present?
    end

  end

end
