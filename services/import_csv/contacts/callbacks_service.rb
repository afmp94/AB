# NOTE: Add only selective callbacks for contacts and its address, email addresses,
# and phone numbers. Please be really selective over here because it will slow
# down the import process a lot. If possible try to handle the logic in import
# service itself like mapping some data/objects to contacts and its asscoated
# objects before its import.

module ImportCsv

  module Contacts

    class CallbacksService

      CONTACT_CALLBACKS = %w(
        call_contact_api
      ).freeze

      def initialize(contact_ids)
        @contact_ids = contact_ids
      end

      def process
        contacts = Contact.where(id: @contact_ids)

        contacts.find_each do |contact|
          CONTACT_CALLBACKS.each do |contact_callback|
            contact.send(contact_callback.to_sym)
          end
        end
      end

    end

  end

end
