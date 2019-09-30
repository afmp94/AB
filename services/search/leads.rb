class Search::Leads

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def fetch(_action_name:, status:, order_by:, sort_direction:, search_term: nil, page: nil)
    if search_term.blank?
      search_leads = leads
      search_leads_responsible_for = leads_responsible_for
    else
      search_leads = leads.search_name(search_term)
      search_leads_responsible_for = leads_responsible_for.search_name(search_term)
    end

    search_leads = filtered_leads(search_leads, search_leads_responsible_for, status, _action_name)

    search_leads.page(page).per(Lead::PER_PAGE).order("#{order_by} #{sort_direction}")
  end

  private

  def leads
    leads = if @user.user_has_teammates?
              Lead.owned_by_team_member(@user.team_member_ids)
            else
              @user.leads
            end
    leads.joins(:contact).includes(:contact)
  end

  def leads_responsible_for
    Lead.leads_responsible_for(@user.team_member_ids).joins(:contact).includes(:contact)
  end

  def filtered_leads(search_leads, search_leads_responsible_for, status, _action_name)
    if lead_responsible_for_filters.include?(status)
      filtered_responsible_leads(search_leads_responsible_for, status)
    elsif lead_filters.include?(status)
      filtered_search_leads(search_leads, status)
    else
      case _action_name
      when "user_leads"
        search_leads.pure_leads.leads_by_status(status)
      else
        search_leads.leads_by_status(status)
      end
    end
  end

  def filtered_responsible_leads(search_leads_responsible_for, status)
    case status
    when "lead_all"
      search_leads_responsible_for
    when "lead_unclaimed"
      search_leads_responsible_for.leads_unclaimed
    end
  end

  def filtered_search_leads(search_leads, status)
    case status
    when "lead_not_contacted"
      search_leads.leads_not_contacted
    when "lead_attempted_contact"
      search_leads.leads_attempted_contact
    when "lead_contacted"
      search_leads.lead_status.leads_contacted
    when "lead_not_converted"
      search_leads.leads_not_converted_status
    when "lead_junk"
      search_leads.leads_junk_status
    when "current_pipeline"
      search_leads.client_current_pipeline_status
    when "all"
      search_leads.client_all_status
    when "not_converted"
      search_leads.client_not_converted_status
    when "long_term_prospect"
      search_leads.client_long_term_prospect_status
    end
  end

  def lead_responsible_for_filters
    %w(lead_all lead_unclaimed)
  end

  def lead_filters
    %w(
      lead_not_contacted
      lead_attempted_contact
      lead_contacted
      lead_not_converted
      lead_junk
      current_pipeline
      all
      not_converted
      long_term_prospect
    )
  end

end
