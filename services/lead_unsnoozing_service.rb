class LeadUnsnoozingService

  def check_and_unsnooze_leads
    Lead.where(active: true).each do |lead|
      if unsnoozing_criteria_are_met(lead) && lead&.created_by_user&.subscription.present?
        if lead.created_by_user.subscription.deactivated_on.nil?
          lead.snoozed_by_id = nil
          lead.snoozed_until = nil
          lead.snoozed_at = nil
          lead.save
        end
      end
    end
  end

  def unsnoozing_criteria_are_met(lead)
    lead.snoozed_by_id &&
      lead.snoozed_until &&
      lead.snoozed_at &&
      (Time.zone.now - lead.snoozed_until) > 0
  end

end
