class DailyLeadsRecapService

  attr_reader :user, :leads

  def initialize(user)
    @user = user
    @leads = leads_received_in_past_72_hours
  end

  def new_leads_count
    leads.count
  end

  def leads_claimed_count
    claimed_by_user.count
  end

  def replied_to_count
    replied_to.count
  end

  def replied_to_percentage
    if leads_claimed_count > 0
      (replied_to_count.to_f / leads_claimed_count.to_f) * 100
    end
  end

  def avg_response_time
    leads_with_response_time = replied_to.where("time_before_attempted_contact IS NOT NULL")

    leads_with_response_time.average(:time_before_attempted_contact)
  end

  def avg_team_response_time
    leads_with_response_time = leads.where("time_before_attempted_contact IS NOT NULL")

    leads_with_response_time.average(:time_before_attempted_contact)
  end

  def leads_needing_action
    leads.where("contacted_status = ?", 0)
  end

  private

  def leads_received_in_past_72_hours
    Lead.initially_leads.owned_or_created_by_user(user).
      created_after_date((Time.zone.now - 3.days)).order("created_at asc")
  end

  def claimed_by_user
    user_leads = leads.where(user: user)
    user_leads.where(state: "claimed")
  end

  def replied_to
    claimed_by_user.where("contacted_status != ?", 0)
  end

end
