class DuplicateContactsIdentifier

  attr_reader :user, :contacts

  def initialize(user=nil, debug: nil)
    @user = user
    @contacts = user.contacts.active
    @debug = debug
  end

  def duplicate_contacts
    rearrange([
      first_and_last_name_matching_records,
      first_or_last_name_with_email_or_phone_matching_records,
      first_and_last_name_very_similar,
      email_matching_records,
      phone_matching_records,
      no_name_with_phone_or_email_address_matching_records
    ].reduce([], :concat).uniq)
  end

  private

  def rearrange(potential_duplicates)
    result = []
    potential_duplicates.each do |group|
      is_add_group = false
      potential_duplicates.each do |sub_group|
        if !common_records?(group, sub_group).empty? && group != sub_group
          is_add_group = true
          result.push((group + sub_group).sort.uniq)
        end
      end
      result.push(group) unless is_add_group
    end
    result.uniq
  end

  def common_records?(array1, array2)
    array1 & array2
  end

  def first_and_last_name_very_similar
    contact_ids = []
    contact_ids = group_by_attribute_for_similar_matching(contacts, contact_ids)
    result = contact_ids.uniq
    log_debug_message(result, __method__)
    result
  end

  def email_matching_records
    contact_ids = []
    grouped_contacts = contacts.
                         joins(:email_addresses).
                         select("contacts.id, email_addresses.email").order("contacts.id").group_by(&:email)
    grouped_contacts.each_value do |array|
      idz = grouping_contacts_for_associated_records(array.map { |c| c["id"] })
      contact_ids <<  idz if array.length > 1 && !idz.empty?
    end
    log_debug_message(contact_ids, __method__)
    contact_ids
  end

  def phone_matching_records
    contact_ids = []
    grouped_contacts = contacts.joins(:phone_numbers).
                         select("contacts.id, phone_numbers.number").order("contacts.id").group_by(&:number)
    grouped_contacts.each_value do |array|
      idz = grouping_contacts_for_associated_records(array.map { |c| c["id"] })
      contact_ids <<  idz if array.length > 1 && !idz.empty?
    end
    log_debug_message(contact_ids, __method__)
    contact_ids
  end

  def grouping_contacts_for_associated_records ids
    list = []
    first_contact = Contact.find(ids[0])
    contact_ids = ids - [ids[0]]
    contact_ids.each do |c|
      c = Contact.find(c)
      if contact_names_matching?(first_contact, c)
        list = list + [ids[0], c.id]
      end
    end
    list
  end

  def contact_names_matching?(first_contact, contact)
    (first_contact.first_name == contact.first_name &&
    first_contact.last_name == contact.last_name &&
    !contact.first_name.nil? && !contact.last_name.nil?) ||
      (contact.first_name == nil && contact.last_name == nil)
  end

  def first_and_last_name_matching_records
    contact_ids = []
    contacts.where("first_name is NOT NULL and last_name is NOT NULL").
      group_by do |x|
        [x.first_name, x.last_name]
      end.each_with_object({}) do |key, _value|
        contact_ids << key[1].collect(&:id).sort if key[1].count > 1
      end
    result = contact_ids.uniq

    log_debug_message(result, __method__)
    result
  end

  def first_or_last_name_with_email_or_phone_matching_records
    contact_ids = []

    contact_ids = group_by_multiple_attributes(contacts, contact_ids, "first_name", "email")
    contact_ids = group_by_multiple_attributes(contacts, contact_ids, "last_name", "email")
    contact_ids = group_by_multiple_attributes(contacts, contact_ids, "first_name", "phone_number")
    contact_ids = group_by_multiple_attributes(contacts, contact_ids, "last_name", "phone_number")

    result = contact_ids.uniq

    log_debug_message(result, __method__)
    result
  end

  def no_name_with_phone_or_email_address_matching_records
    contact_ids = []
    query_contacts = contacts_with_first_or_last_name_null
    contact_ids = group_by_attribute(query_contacts, contact_ids, "email")
    contact_ids = group_by_attribute(query_contacts, contact_ids, "phone_number")

    result = contact_ids.uniq

    log_debug_message(result, __method__)
    result
  end

  def group_by_attribute(contacts, ids, attribute)
    contacts.where("#{attribute} is NOT NULL").
      group_by do |x|
        [x.send(attribute)]
      end.each_with_object({}) do |key, _value|
        ids << key[1].collect(&:id).sort if key[1].count > 1
      end
    ids
  end

  def group_by_attribute_for_similar_matching(contacts, ids)
    contacts.where("first_name is NOT NULL AND last_name is NOT NULL").
      group_by do |contact|
        [contact.send("first_name").to_s[0..5].downcase, contact.send("last_name").to_s[0..5].downcase]
      end.each_with_object({}) do |key, _value|
        ids << key[1].collect(&:id).sort if key[1].count > 1
      end
    ids
  end

  def contacts_with_first_or_last_name_null
    contacts.where("first_name is NULL and last_name is NULL")
  end

  def group_by_multiple_attributes(contacts, ids, attribute1, attribute2)
    contacts.where("#{attribute1} is NOT NULL AND #{attribute2} is NOT NULL").
      group_by do |x|
        [x.send(attribute1), x.send(attribute2)]
      end.each_with_object({}) do |key, _value|
        ids << key[1].collect(&:id).sort if key[1].count > 1
      end
    ids
  end

  def log_debug_message(contact_ids, method)
    if @debug && contact_ids.any?
      Rails.logger.info "#{method} found"
      Rails.logger.info "   * contact_ids: #{contact_ids}"
    end
  end

end
