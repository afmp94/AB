class LeadMerger

  attr_reader :primary_lead, :selected_assoc, :lead_ids

  def initialize(lead_ids)
    @lead_ids = lead_ids
    set_primary_lead(lead_ids)

    @selected_assoc = primary_lead.class.reflect_on_all_associations.select do |assoc|
      ["has_many", "has_one"].include?(assoc.macro.to_s) && !tag_association?(assoc)
    end
    @timestamp = Time.now.to_s
  end

  def merge
    copy_record_attributes(lead_ids)
    copy_record_associations(lead_ids)
    set_merge_data
    primary_lead
  rescue StandardError => e
    Rails.logger.error e.to_s
  end

  private

  def copy_association(lead1, lead2)
    ActiveRecord::Base.transaction do
      selected_assoc.each do |assoc|
        if has_many_association?(assoc, lead2)
          update_has_many_associations(assoc, lead1, lead2)
        elsif has_one_assocation?(assoc, lead2)
          update_has_one_associations(assoc, lead1, lead2)
        end
      end
    end
  end

  def copy_record_associations(lead_ids)
    l_ids = lead_ids - [primary_lead.id]
    l_ids.each do |lead_id|
      copy_association(primary_lead, Lead.find(lead_id))
    end
  end

  def copy_record_attributes(lead_ids)
    l_ids = lead_ids - [primary_lead.id]
    l_ids.each do |lead_id|
      copy_attribute(primary_lead, Lead.find(lead_id))
    end
  end

  def copy_attribute(lead1, lead2)
    Lead.column_names.each do |attribute_name|
      lead1[attribute_name] = lead1.send(attribute_name) || lead2.send(attribute_name)
    end
    lead1.save
  end

  def set_primary_lead(lead_ids)
    @primary_lead = Lead.find(lead_ids[0])
    lead_ids.each do |lead_id|
      compare_two_lead(primary_lead, Lead.find(lead_id)) if lead_id != primary_lead.id
    end
  end

  def compare_two_lead(lead1, lead2)
    @primary_lead = if by_task_count?(lead1, lead2) || by_contact_activity?(lead1, lead2) ||
                       by_names?(lead1) || by_properties?(lead1, lead2) ||
                       by_created_at?(lead1, lead2)
                      lead1
                    else
                      lead2
                    end
  end

  def by_task_count?(lead1, lead2)
    lead1.tasks.count > lead2.tasks.count
  end

  def by_contact_activity?(lead1, lead2)
    lead1.contact_activities.count > lead2.contact_activities.count
  end

  def by_names?(lead1)
    lead1.name.present?
  end

  def by_properties?(lead1, lead2)
    lead1.properties.count > lead2.properties.count
  end

  def by_created_at?(lead1, lead2)
    lead1.created_at > lead2.created_at
  end

  def tag_association?(assoc)
    assoc.name.to_s.include?("tag")
  end

  def has_one_assocation?(assoc, lead)
    lead.send(assoc.name).present? && assoc.macro == :has_one
  end

  def has_many_association?(assoc, lead)
    lead.send(assoc.name).present? && assoc.macro == :has_many
  end

  def update_has_many_associations(assoc, lead1, lead2)
    lead2.send(assoc.name).each do |record|
      record[assoc.foreign_key] = lead1.id
      record.save
    end
  end

  def update_has_one_associations(assoc, lead1, lead2)
    record = lead2.send(assoc.name)
    record[assoc.foreign_key] = lead1.id
    record.save
  end

  def set_merge_data
    merged_lead_ids = lead_ids - [primary_lead.id]
    merge_data = primary_lead.merge_data
    data = [merged_leads_ids: merged_lead_ids, timestamp: @timestamp]
    merge_data << data
    primary_lead.merge_data = merge_data
    primary_lead.save
    disable_merged_leads(merged_lead_ids)
  end

  def disable_merged_leads(lead_ids)
    Lead.where(id: lead_ids).update_all(active: false)
  end

end
