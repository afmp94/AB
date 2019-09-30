class ContactMerger

  attr_reader :primary_contact, :selected_assoc, :contact_ids

  def initialize(contact_ids)
    @contact_ids = contact_ids
    set_primary_contact(contact_ids)
    @selected_assoc = primary_contact.class.reflect_on_all_associations.select do |assoc|
      ["has_many", "has_one"].include?(assoc.macro.to_s) && !tag_association?(assoc)
    end
    @timestamp = Time.now.to_s
  end

  def merge
    copy_record_attributes(contact_ids)
    copy_record_associations(contact_ids)
    set_merge_data
    primary_contact
  rescue StandardError => e
    Rails.logger.error e.to_s
  end

  private

  def copy_record_associations(contact_ids)
    c_ids = contact_ids - [primary_contact.id]
    c_ids.each do |contact_id|
      copy_association(primary_contact, Contact.find(contact_id))
    end
  end

  def copy_association(contact1, contact2)
    ActiveRecord::Base.transaction do
      selected_assoc.each do |assoc|
        if has_many_association?(assoc, contact2)
          update_has_many_associations(assoc, contact1, contact2)
        elsif has_one_assocation?(assoc, contact2)
          update_has_one_associations(assoc, contact1, contact2)
        end
      end
    end
  end

  def copy_record_attributes(contact_ids)
    c_ids = contact_ids - [primary_contact.id]
    c_ids.each do |contact_id|
      copy_attribute(primary_contact, Contact.find(contact_id))
    end
  end

  def copy_attribute(contact1, contact2)
    Contact.column_names.each do |attribute_name|
      contact1[attribute_name] = contact1.send(attribute_name) || contact2.send(attribute_name)
    end
    contact1.save
  end

  def set_primary_contact(contact_ids)
    # compare each contact by conditions and set primary contact
    @primary_contact = Contact.find(contact_ids[0])
    contact_ids.each do |contact_id|
      compare_two_contact(primary_contact, Contact.find(contact_id)) if contact_id != primary_contact.id
    end
  end

  def compare_two_contact(contact1, contact2)
    @primary_contact = if by_leads_count?(contact1, contact2) || by_contact_activity?(contact1, contact2) ||
                          by_names?(contact1) || by_email_address_and_phone_numbers?(contact1, contact2) ||
                          by_created_at?(contact1, contact2)
                         contact1
                       else
                         contact2
                       end
  end

  def by_leads_count?(contact1, contact2)
    contact1.leads.count > contact2.leads.count
  end

  def by_contact_activity?(contact1, contact2)
    contact1.contact_activities.count > contact2.contact_activities.count
  end

  def by_names?(contact)
    (contact.first_name && contact.last_name) || false
  end

  def by_email_address_and_phone_numbers?(contact1, contact2)
    (contact1.email_addresses.count + contact1.phone_numbers.count) >
      (contact2.email_addresses.count + contact2.phone_numbers.count)
  end

  def by_created_at?(contact1, contact2)
    contact1.created_at > contact2.created_at
  end

  def has_one_assocation?(assoc, contact)
    contact.send(assoc.name).present? && assoc.macro == :has_one
  end

  def has_many_association?(assoc, contact)
    contact.send(assoc.name).present? && assoc.macro == :has_many
  end

  def update_has_many_associations(assoc, contact1, contact2)
    # here we need to call save on each for audits
    contact2.send(assoc.name).each do |record|
      record[assoc.foreign_key] = contact1.id
      record.save
    end
  end

  def update_has_one_associations(assoc, contact1, contact2)
    record = contact2.send(assoc.name)
    record[assoc.foreign_key] = contact1.id
    record.save
  end

  def tag_association?(assoc)
    assoc.name.to_s.include?("tag")
  end

  def set_merge_data
    merged_contact_ids = contact_ids - [primary_contact.id]
    merge_data = primary_contact.merge_data
    data = [merged_contact_ids: merged_contact_ids, timestamp: @timestamp]
    merge_data << data
    primary_contact.merge_data = merge_data
    primary_contact.save
    disable_merged_contacts(merged_contact_ids)
  end

  def disable_merged_contacts(contact_ids)
    Contact.where(id: contact_ids).update_all(active: false)
  end

end
