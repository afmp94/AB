class Contact

  class ParserIOS < ApplicationService

    def initialize(params={})
      @params = params.fetch(:attributes_collection, [])
      @user   = params[:user]
    end

    def call
      contacts_attributes_collection
    end

    private

    attr_reader :user

    def contacts_attributes_collection
      params.map { |contact_params| contact_attributes(contact_params) }
    end

    def contact_attributes(contact_params)
      {
        last_name:                  contact_params["lastName"],
        first_name:                 contact_params["firstName"],
        phone_numbers_attributes:   nested_attributes(contact_params.fetch("phoneNumbers", []), :number),
        email_addresses_attributes: nested_attributes(contact_params.fetch("emailAddresses", []), :email),
        addresses_attributes:       nested_attributes(contact_params.fetch("addresses", [])),
        user_id:                    user&.id,
        ios_contact_id:             contact_params["recordId"],
        linked_id:                  contact_params.fetch("linkedRecordIds", []).first
      }
    end

    def nested_attributes(values, field=nil)
      values.map do |data|
        next format_attributes_for_nested(data.to_h) if field.blank?

        { field.to_sym => Contact::FormatterIOS.(value: data, field: field) }
      end
    end

    def format_attributes_for_nested(data)
      data.map { |key, value| [key.to_sym, Contact::FormatterIOS.(value: value, field: key)] }.to_h
    end

  end

end
