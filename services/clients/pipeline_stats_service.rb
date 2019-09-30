module Clients

  class PipelineStatsService

    attr_reader :user, :individual_leads, :team_leads

    def initialize(user)
      @user             = user
      @individual_leads = user.leads
      @team_leads       = Lead.owned_by_team_member(user.team_member_ids)
    end

    # Individual Pipeline Stats
    def individual_prospect_leads_price
      prospect_leads(individual_leads).sum(:displayed_price).to_i
    end

    def individual_prospect_leads_commission
      prospect_leads(individual_leads).sum(:displayed_net_commission).to_i
    end

    def individual_prospect_leads_count
      prospect_leads(individual_leads).count
    end

    def individual_active_leads_price
      active_leads(individual_leads).sum(:displayed_price).to_i
    end

    def individual_active_leads_commission
      active_leads(individual_leads).sum(:displayed_net_commission).to_i
    end

    def individual_active_leads_count
      active_leads(individual_leads).count
    end

    def individual_pending_leads_price
      pending_leads(individual_leads).sum(:displayed_price).to_i
    end

    def individual_pending_leads_commission
      pending_leads(individual_leads).sum(:displayed_net_commission).to_i
    end

    def individual_pending_leads_count
      pending_leads(individual_leads).count
    end

    def individual_closed_ytd_leads_price
      closed_ytd_leads(individual_leads).sum(:displayed_price).to_i
    end

    def individual_closed_ytd_leads_commission
      closed_ytd_leads(individual_leads).sum(:displayed_net_commission).to_i
    end

    def individual_closed_ytd_leads_count
      closed_ytd_leads(individual_leads).count
    end

    # Team Pipeline Statas
    def team_prospect_leads_price
      prospect_leads(team_leads).sum(:displayed_price).to_i
    end

    def team_prospect_leads_commission
      prospect_leads(team_leads).sum(:displayed_net_commission).to_i
    end

    def team_prospect_leads_count
      prospect_leads(team_leads).count
    end

    def team_active_leads_price
      active_leads(team_leads).sum(:displayed_price).to_i
    end

    def team_active_leads_commission
      active_leads(team_leads).sum(:displayed_net_commission).to_i
    end

    def team_active_leads_count
      active_leads(team_leads).count
    end

    def team_pending_leads_price
      pending_leads(team_leads).sum(:displayed_price).to_i
    end

    def team_pending_leads_commission
      pending_leads(team_leads).sum(:displayed_net_commission).to_i
    end

    def team_pending_leads_count
      pending_leads(team_leads).count
    end

    def team_closed_ytd_leads_price
      closed_ytd_leads(team_leads).sum(:displayed_price).to_i
    end

    def team_closed_ytd_leads_commission
      closed_ytd_leads(team_leads).sum(:displayed_net_commission).to_i
    end

    def team_closed_ytd_leads_count
      closed_ytd_leads(team_leads).count
    end

    private

    def prospect_leads(leads)
      leads.leads_by_status(1)
    end

    def active_leads(leads)
      leads.leads_by_status(2)
    end

    def pending_leads(leads)
      leads.leads_by_status(3)
    end

    def closed_ytd_leads(leads)
      leads.closed_leads_after_date(Time.current.beginning_of_year)
    end

  end

end
