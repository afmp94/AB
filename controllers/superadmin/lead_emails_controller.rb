class Superadmin::LeadEmailsController < ApplicationController

  before_action :set_lead_email, only: [:show, :view_yaml]
  before_action :authenticate_superadmin_user!

  def index
    @lead_emails = LeadEmail.page(params[:page]).order("created_at desc").load
    @all_lead_emails = LeadEmail.all
    @today_emails = today_emails
    @week_emails = week_emails
    @month_emails = month_emails
  end

  def show
    @lead_email_html_string = @lead_email.html.to_s
  end

  def view_yaml
    render plain: @lead_email.attributes.to_yaml
  end

  private

  def set_lead_email
    @lead_email = LeadEmail.find(params[:id])
  end

  def today_emails
    @all_lead_emails.where("created_at >= ?", Time.zone.now - 24.hours)
  end

  def week_emails
    @all_lead_emails.where("created_at >= ?", Time.zone.now - 7.days)
  end

  def month_emails
    @all_lead_emails.where("created_at >= ?", Time.zone.now - 30.days)
  end

end
