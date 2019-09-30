class DesignsController < ApplicationController

  skip_before_action :authenticate_user!

  def calendar_monthly
    render "designs/calendar/monthly"
  end

  def calendar_new
    render "designs/calendar/new"
  end

  def coaching_coaching
    render "designs/coaching/coaching"
  end

  def coaching_index
    render "designs/coaching/index"
  end

  def coaching_show
    render "designs/coaching/show"
  end

  def drip_campaigns_index
    render "designs/drip_campaigns/index"
  end

  def drip_campaigns_edit
    render "designs/drip_campaigns/edit"
  end

  def email_campaigns_index
    render "designs/email_campaigns/index"
  end

  def email_campaigns_edit
    render "designs/email_campaigns/edit"
  end

  def email_campaigns_edit_basic
    render "designs/email_campaigns/edit_basic"
  end

  def email_campaigns_show
    render "designs/email_campaigns/show"
  end

  def sms_messaging_lead_text_sms_form
    render "designs/sms_messaging/lead_text_sms_form"
  end

  def sms_messaging_text_settings
    render "designs/sms_messaging/text_settings"
  end

  def sms_messaging_add_text_templates
    render "designs/sms_messaging/add_text_templates"
  end

  def action_plans_index
    render "designs/action_plans/index"
  end

  def action_plans_edit
    render "designs/action_plans/edit"
  end

  def action_plans_show
    render "designs/action_plans/show"
  end

  def onboarding_index
    render "designs/onboarding/index"
  end

  def onboarding_index_speed
    render "designs/onboarding/speed"
  end

  def onboarding_getting_started
    render "designs/onboarding/getting_started"
  end

  def contacts_index
    render "designs/contacts/index"
  end

  def contacts_edit_groups
    render "designs/contacts/edit_groups"
  end

  def contacts_recent_contacts
    render "designs/contacts/recent_contacts"
  end

  def contacts_sorting
    render "designs/contacts/sorting"
  end

  def agent_assessment
    render "designs/survey_results/agent_assessment"
  end

  def assessment_payment
    render "designs/assessment/payment"
  end

  def action_plans_show
    render "designs/action_plans/show"
  end

  def templates_assessment_marketing
    render "designs/templates/assessment_marketing"
  end

  def templates_dashboard
    render "designs/templates/dashboard"
  end

  def templates_show
    render "designs/templates/show"
  end

  def templates_index
    render "designs/templates/index"
  end

  def templates_join_with_marketing
    render "designs/templates/join_with_marketing"
  end

  def templates_import_contacts_new_format
    render "designs/templates/import_contacts_new_format"
  end

  def templates_settings
    render "designs/templates/settings"
  end

  def templates_new
    render "designs/templates/new"
  end

  def templates_welcome
    render "designs/templates/welcome"
  end

  def broker_agent_index
    render "designs/broker/agent_index"
  end

  def broker_agent_edit
    render "designs/broker/agent_edit"
  end

  def broker_organization
    render "designs/broker/organization"
  end

end
