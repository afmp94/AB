class Contact

  class SquasherIOS < ApplicationService

    def initialize(params={})
      @params             = params.fetch(:attributes_collection, [])
      @contact_attributes = params.fetch(:contact_attributes, {})
      @relations          = params.fetch(:relations, [])
    end

    def call
      return prepare! if linked_contact_attributes.blank?

      squash_contacts!
    end

    private

    attr_reader :contact_attributes, :relations

    def prepare!
      contact_attributes.delete(:linked_id)
    end

    def replace_main!
      temp = contact_attributes.clone
      contact_attributes.replace(linked_contact_attributes)
      linked_contact_attributes.replace(temp)
    end

    def squash_contacts!
      replace_main! unless main?
      prepare!

      squashed_attributes_collection.each do |squashed_attributes|
        squash_nested!(squashed_attributes)

        params.delete(squashed_attributes)
      end
    end

    def squash_nested!(squashed_attributes)
      relations.each { |relation| squash!(squashed_attributes, relation) }
    end

    def squash!(squashed_attributes, relation)
      get_nested_attributes(squashed_attributes, relation).each do |from_attributes|
        nested_attributes = get_nested_attributes(contact_attributes, relation)

        next if nested_attributes.any? { |to_attributes| from_attributes == to_attributes }

        nested_attributes << from_attributes
      end
    end

    def select_linked_contacts_by(field, value, limit=false)
      params.send(limit ? :find : :select) { |attributes| attributes[field] == value }
    end

    def main?
      return true if linked_contact_attributes[:linked_id].blank?

      [contact_attributes, linked_contact_attributes].
        map { |attributes| select_linked_contacts_by(:linked_id, attributes[:ios_contact_id]).length }.each_cons(2).
        any? { |contact_squashed_count, linked_squashed_count| contact_squashed_count > linked_squashed_count }
    end

    def get_nested_attributes(attributes, relation)
      Array(attributes["#{relation}_attributes".to_sym])
    end

    def linked_contact_attributes
      @linked_contact_attributes ||= select_linked_contacts_by(:ios_contact_id, contact_attributes[:linked_id], true)
    end

    def squashed_attributes_collection
      @squashed_attributes_collection ||= select_linked_contacts_by(:linked_id, contact_attributes[:ios_contact_id])
    end

  end

end
