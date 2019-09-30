class Contact

  class NestedRelationsResolverIOS < ApplicationService

    def initialize(params={})
      @params       = params.fetch(:attributes, {})
      @contact      = params[:contact]
      @dependencies = params.fetch(:dependencies, {})
    end

    def call
      dependencies.each_pair { |relation, fields| remove_duplicates!(relation, fields) }

      params
    end

    private

    attr_reader :contact, :dependencies

    def remove_duplicates!(relation, fields)
      nested_attributes = params["#{relation}_attributes".to_sym]
      return if nested_attributes.blank?

      clear_duplicates!(nested_attributes, relation, fields)
    end

    def clear_duplicates!(nested_attributes, relation, fields)
      uniq_records = nested_attributes.map do |attributes|
        next if contact.send(relation).where(conditions(attributes, fields)).present?

        attributes
      end

      nested_attributes.replace(uniq_records.compact)
    end

    def conditions(attributes, fields)
      fields.map { |field| [field, Contact::FormatterIOS.(value: attributes[field], field: field)] }.to_h
    end

  end

end
