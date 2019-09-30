require "activerecord-import/base"
ActiveRecord::Import.require_adapter("postgresql")

module NylasApi

  class ImportContactsService

    include Common::ContactsImportHelper

    BLACKLISTED_EMAILS_FROM = %w(
      mailer-daemon
      reply
      noreply
      no-reply
      alerts
      alert
      donotreply
    ).freeze

    attr_reader :user, :account

    def initialize(user)
      @user = user
      @account = NylasApi::Account.new(user.nylas_token).retrieve
    end

    def process
      new_contacts           = []
      failed_contact_data    = []
      invalid_data           = []

      total_imported_records = 0
      total_failed_records   = 0

      account.contacts.execute.each do |contact|
        begin
          contact_data = contact
          if contact_valid?(contact_data)
            new_contact = Contact.new(name: "#{contact_data[:given_name]} #{contact_data[:surname]}".to_s)
            build_email_addresses(new_contact, contact_data)
            build_phone_numbers(new_contact, contact_data)
            set_contact_mandatory_fields(new_contact, user)
            set_other_fields(new_contact) do |new_contact|
              new_contact.populate_first_name_and_last_name_from_name
            end
            handle_validations(new_contact)
            set_primary_to_email_and_phone(new_contact)
            new_contacts << new_contact
            total_imported_records += 1
            Rails.logger.info "#{new_contact.email} - #{new_contact.name} imported!!!"
            Rails.logger.info "[Nylas.contact_importing] Current processing contact got passed for importing #{total_imported_records}"
          else
            Rails.logger.info "[Nylas.contact_importing] Current processing contact is invalid #{contact_data}"
            invalid_data << contact_data
          end
        rescue => e
          total_failed_records += 1
          Rails.logger.info "[Nylas.contact_importing] Current processing contact got failed #{total_failed_records}"
          Rails.logger.info "Error: #{e.message}"
          failed_contact_data << [contact_data, e.message]
        end
      end

      if new_contacts.present?
        results = create_contacts_for(new_contacts)
        ImportCsv::Contacts::CallbacksService.new(results.ids).delay.process
        user.update!(imported_nylas_contacts: true) if results.ids.present?
      end

      update_ungraded_contacts_count_for_user
    end

    private

    def create_contacts_for(new_contacts)
      Contact.import new_contacts, recursive: true, validate: false
    end

    def update_ungraded_contacts_count_for_user
      user.update!(ungraded_contacts_count: user.contacts.active.ungraded.count)
    end

    def contact_valid?(contact_data)
      valid = false

      if contact_data[:object] == "contact"
        valid = true
      end

      if valid && contact_data[:given_name].present?
        valid = true
      end

      if valid
        email_address = contact_data[:emails][0][:email].downcase
        BLACKLISTED_EMAILS_FROM.each do  |blacklisted_email_from|
          if email_address.include?(blacklisted_email_from)
            valid = false
            break
          end
        end
      end

      return valid
    end

    def build_phone_numbers(new_contact, contact_data)
      if contact_data[:phone_numbers].present?
        phone_numbers = []

        contact_data[:phone_numbers].each do |phone_number|
          phone_numbers << PhoneNumber.new(number: phone_number["number"])
        end

        new_contact.phone_numbers = phone_numbers
      end

      new_contact
    end

    def build_email_addresses(new_contact, contact_data)
      new_contact.email_addresses << EmailAddress.new(email: contact_data[:emails][0][:email])

      new_contact
    end

  end

end
