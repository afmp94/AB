class ReportsController < ApplicationController

  require "date"

  def index
    render "index"
  end

  def buyers
    @leads = current_user.leads.buyers.leads_by_status(2).order("name ASC")
    render "reports/buyers"
  end

  def buyers_team
    @leads = current_user.team_leads.buyers.leads_by_status(2).order("name ASC")
    render "reports/buyers_team"
  end

  def cash_flow
    set_date_range
    @leads_closing_in_next_12_months = current_user.
                                       leads.
                                       clients_active_and_closed_excluding_prosects_and_paused.
                                       where(displayed_closing_date_at: Time.zone.now.beginning_of_month..Time.zone.now.beginning_of_month + 1.year)
    @lead_months = @leads_closing_in_next_12_months.group_by { |t| t.displayed_closing_date_at.beginning_of_month }
    render "cash_flow"
  end

  def cash_flow_team
    set_date_range
    @leads_closing_in_next_12_months = current_user.
                                       team_leads.
                                       clients_active_and_closed_excluding_prosects_and_paused.
                                       where(displayed_closing_date_at: Time.zone.now.beginning_of_month..Time.zone.now.beginning_of_month + 1.year)
    @lead_months = @leads_closing_in_next_12_months.group_by { |t| t.displayed_closing_date_at.beginning_of_month }
    render "cash_flow_team"
  end

  def closed
    @ytd_leads = current_user.leads.leads_by_status(4).year_to_date_leads.
                 order("displayed_closing_date_at")

    @last_year_leads = current_user.leads.leads_by_status(4).last_year_leads.
                       order("displayed_closing_date_at")

    @past_12_months_leads = current_user.leads.leads_by_status(4).past_12_months_leads.
                            order("displayed_closing_date_at")

    @all_leads = current_user.leads.leads_by_status(4).
                 order("displayed_closing_date_at")

    render "reports/closed"
  end

  def closed_team
    @ytd_leads = current_user.team_leads.leads_by_status(4).year_to_date_leads.
                 order("displayed_closing_date_at")

    @last_year_leads = current_user.team_leads.leads_by_status(4).last_year_leads.
                       order("displayed_closing_date_at")

    @past_12_months_leads = current_user.team_leads.leads_by_status(4).past_12_months_leads.
                            order("displayed_closing_date_at")

    @all_leads = current_user.team_leads.leads_by_status(4).
                 order("displayed_closing_date_at")

    render "reports/closed_team"
  end

  def listings
    @leads = current_user.leads.sellers.leads_by_status(2).order("created_at ASC")
    render "reports/listings"
  end

  def listings_team
    @leads = current_user.team_leads.sellers.leads_by_status(2).order("created_at ASC")
    render "reports/listings_team"
  end

  def pendings
    @leads = current_user.leads.leads_by_status(3).order("displayed_closing_date_at ASC")
    render "reports/pendings"
  end

  def pendings_team
    @leads = current_user.team_leads.leads_by_status(3).order("displayed_closing_date_at ASC")
    render "reports/pendings_team"
  end

  def lead_source
    @leads = current_user.leads
    @clients = @leads.client_all_status
    @not_converted_or_junk = @leads.leads_not_converted_or_junk_status

    render "reports/lead_source"
  end

  def lead_source_team
    @leads = current_user.team_leads
    @clients = @leads.client_all_status
    @not_converted_or_junk = @leads.leads_not_converted_or_junk_status

    render "reports/lead_source_team"
  end

  private

  def set_date_range
    @range = (0..11).map { |i| (Time.zone.now.beginning_of_month + i.months) }
  end

end
