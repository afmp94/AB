class UndoMerge

  attr_reader :primary_record, :timestamp, :selected_assoc, :record_ids

  def initialize(primary_record)
    @primary_record = primary_record

    @record_ids = if primary_record.class.to_s == "Contact"
                    value_from_hash("merged_contact_ids")
                  else
                    value_from_hash("merged_leads_ids")
                  end
    initial_setup
  end

  def undo
    undo_primary_attributes
    undo_association
    enable_contacts if primary_record.class.to_s == "Contact"
    enable_leads if primary_record.class.to_s == "Lead"
  end

  private

  def enable_contacts
    Contact.where(id: value_from_hash("merged_contact_ids")).update_all(active: true)
  end

  def enable_leads
    Lead.where(id: value_from_hash("merged_leads_ids")).update_all(active: true)
  end

  def initial_setup
    @timestamp = Time.parse(value_from_hash("timestamp"))
    @selected_assoc = primary_record.class.reflect_on_all_associations.select do |assoc|
      ["has_many", "has_one"].include?(assoc.macro.to_s) && !tag_association?(assoc)
    end
  end

  def associated_audits associated_record
    associated_record&.audits&.where("action = ? and created_at > ?",
                                     "update", @timestamp)&.order("id desc")
  end

  def undo_association
    ActiveRecord::Base.transaction do
      selected_assoc.each do |assoc|
        if assoc.macro.to_s == "has_many"
          primary_record.send(assoc.name)&.each do |associated_record|
            asoc_record_adts = associated_audits(associated_record)
            undo_attributes(associated_record, asoc_record_adts) if asoc_record_adts.present?
          end
        else
          associated_record = primary_record.send(assoc.name)
          asoc_record_adts = associated_audits(associated_record)
          undo_attributes(associated_record, asoc_record_adts) if asoc_record_adts.present?
        end
      end
    end
  end

  def tag_association?(assoc)
    ["activities", "tag", "audits"].include?(assoc.name.to_s)
  end

  def undo_primary_attributes
    record_audits = primary_record.audits.where("action = ? and created_at > ?",
                                                "update", @timestamp).order("id desc")

    undo_attributes(primary_record, record_audits)
  end

  def undo_attributes record, audits
    audits.each do |audit|
      audit.audited_changes.each do |audit_change|
        record[audit_change[0]] = audit_change[1][0] unless audit_change[0] == "merge_data"
      end
    end
    record.without_auditing do
      record.save
    end
  end

  def value_from_hash(key)
    YAML.safe_load(primary_record.merge_data.last[0].
      gsub("{:", "{'").
      gsub("=>", "': ").
      gsub(" :", "'"))[key]
  end

end
