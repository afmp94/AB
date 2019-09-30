class Contact

  class TransactionPerformerIOS < ApplicationService

    def initialize(params={})
      @params = params.fetch(:attributes_collection, [])
      @user   = params[:user]
    end

    def call
      params.each { |contact_attributes| create_or_update(contact_attributes.deep_symbolize_keys) }
    end

    private

    attr_reader :user

    def create_or_update(contact_attributes)
      Contact::SquasherIOS.(
        attributes_collection: params,
        contact_attributes: contact_attributes,
        relations: dependencies.keys
      )

      contact = find_or_initialize(contact_attributes)

      begin
        return create(contact, contact_attributes) if contact.new_record?
      rescue ActiveRecord::ValueTooLong => e
        Rails.logger.info "Error for ActiveRecord::ValueTooLong"
        Rails.logger.info "[ImportContctsIOSJob::Error]: contact: #{contact.inspect}"
        Rails.logger.info "[ImportContctsIOSJob::Error]: contact attributes: #{contact_attributes.inspect}"
        Rails.logger.error e.message
      end

      update(contact, contact_attributes)
    end

    def update(contact, contact_attributes)
      contact_attributes = NestedRelationsResolverIOS.(
        attributes:   contact_attributes,
        contact:      contact,
        dependencies: dependencies
      )

      contact.update(contact_attributes)
    end

    def create(contact, contact_attributes)
      contact_attributes[:created_by_user_id] = user.id
      contact.update(contact_attributes)
    end

    def find_or_initialize(contact_attributes)
      contact = Contact.find_by(
        ios_contact_id: contact_attributes[:ios_contact_id],
        user_id:        contact_attributes[:user_id]
      )

      return contact if contact.present?

      contacts = Contact.includes(*additional_dependencies).where(default_conditions(contact_attributes))
      contact  = persisted_record(contacts, contact_attributes)

      return Contact.new(default_conditions(contact_attributes)) if contact.blank?

      contact
    end

    def persisted_record(contacts, contact_attributes)
      contacts.each do |contact|
        persisted = dependencies.any? do |relation, fields|
          not_persisted?(contact, contact_attributes, relation, fields)
        end

        return contact unless persisted
      end

      nil
    end

    def not_persisted?(contact, contact_attributes, relation, fields)
      (pluck(contact_attributes, relation, fields) - contact.send(relation).pluck(*fields).
        map { |values| Array(values) }).present?
    end

    def pluck(contact_attributes, relation, fields)
      contact_attributes["#{relation}_attributes".to_sym].map { |attributes| get_fields(attributes, fields) }
    end

    def get_fields(attributes, fields)
      fields.map { |field| attributes[field] }
    end

    def default_conditions(contact_attributes)
      {
        first_name: contact_attributes[:first_name],
        last_name:  contact_attributes[:last_name],
        user_id:    contact_attributes[:user_id]
      }
    end

    def dependencies
      @dependencies ||= {
        phone_numbers:   %i(number),
        email_addresses: %i(email),
        addresses:       %i(street city state address_type zip)
      }
    end

    def additional_dependencies
      @additional_dependencies ||= %i(user taggings)
    end

  end

end
