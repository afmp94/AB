module HelpHelper

  def help_button_link
    "https://agentbright.com/support/knowledge-base/#{support_article}"
  end

  private

  def support_article
    case controller_name
    when "dashboard"
      dashboard_support_article
    when "home"
      dashboard_support_article
    when "assessments"
      assessment_support_article
    when "contacts"
      contacts_support_article
    when "contact_activities"
      contact_activities_support_article
    when "email_campaigns"
      email_campaigns_support_article
    when "general_notifications"
      general_notifications_support_article
    when "goals"
      goals_support_article
    when "leads"
      leads_support_article
    when "lead_groups"
      lead_groups_support_article
    when "lead_settings"
      lead_settings_support_article
    when "marketing_center"
      marketing_center_support_article
    when "profiles"
      profiles_support_article
    when "reports"
      reports_support_article
    when "registrations"
      registrations_support_article
    when "tasks"
      tasks_support_article
    when "teams"
      teams_support_article
    when "upload_contacts"
      upload_contacts_support_article
    when "users"
      users_support_article
    end
  end

  def assessment_support_article
    case action_name
    when "agent_assessment"
      "article-categories/assessments/"
    else
      "article-categories/assessments/"
    end
  end

  def contacts_support_article
    case action_name
    when "index"
      "article-categories/contacts/"
    when "show"
      "article-categories/contacts-details/"
    when "top_contacts"
      "article-categories/contacts/"
    when "rank"
      "article-categories/rank-contacts/"
    else
      "article-categories/contacts/"
    end
  end

  def contact_activities_support_article
    case action_name
    when "index"
      "article-categories/referral-generation/"
    else
      "article-categories/referral-generation/"
    end
  end

  def dashboard_support_article
    "article-categories/dashboard/"
  end

  def email_campaigns_support_article
    case action_name
    when "index"
      "article-categories/email-campaigns-tracking/"
    when "show"
      "article-categories/email-campaigns-tracking/"
    else
      "article-categories/email-campaigns-tracking/"
    end
  end

  def general_notifications_support_article
    case action_name
    when "index"
      "article-categories/notifications/"
    else
      "article-categories/notifications/"
    end
  end

  def goals_support_article
    case action_name
    when "edit"
      "article-categories/goal-setting/"
    else
      "article-categories/goal-setting/"
    end
  end

  def leads_support_article
    case action_name
    when "index"
      "article-categories/client-home/"
    when "user_leads"
      "article-categories/lead-home/"
    when "new_lead_lead"
      "article-categories/add-lead/"
    when "show"
      "article-categories/lead-detail/"
    when "new"
      "article-categories/add-client/"
    else
      "article-categories/client-home/"
    end
  end

  def lead_groups_support_article
    case action_name
    when "index"
      "article-categories/lead-sharing/"
    else
      "article-categories/lead-sharing/"
    end
  end

  def lead_settings_support_article
    case action_name
    when "quicklink"
      "article-categories/lead-public-link/"
    when "lead_notifications"
      "article-categories/lead-notifications/"
    when "away_settings"
      "article-categories/away-settings/"
    when "lead_services"
      "article-categories/automatic-lead-import/"
    else
      "article-categories/lead_settings/"
    end
  end

  def marketing_center_support_article
    case action_name
    when "index"
      "article-categories/marketing-center/"
    else
      "article-categories/marketing-center/"
    end
  end

  def profiles_support_article
    case action_name
    when "edit_integrations"
      "article-categories/email/"
    else
      "article-categories/profile-setting-updating-personal-details/"
    end
  end

  def registrations_support_article
    case action_name
    when "edit"
      "article-categories/password/"
    else
      "article-categories/password/"
    end
  end

  def reports_support_article # not used
    case action_name
    when "index"
      "article-categories/reports/"
    else
      "article-categories/reports/"
    end
  end

  def tasks_support_article
    case action_name
    when "index"
      "article-categories/tasks/"
    when "new"
      "article-categories/add-tasks/"
    else
      "article-categories/tasks/"
    end
  end

  def teams_support_article
    case action_name
    when "index"
      "article-categories/teams-overview/"
    else
      "article-categories/team-overview/"
    end
  end

  def upload_contacts_support_article
    case action_name
    when "new"
      "article-categories/importing-contacts/"
    else
      "article-categories/importing-contacts/"
    end
  end

  def users_support_article
    case action_name
    when "billing"
      "article-categories/billing/"
    else
      "article-categories/billing/"
    end
  end

end
