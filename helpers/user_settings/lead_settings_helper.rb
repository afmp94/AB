module UserSettings::LeadSettingsHelper

  def display_auto_respond_status(lead_setting_view_service)
    if lead_setting_view_service.email_auto_respond_status_on?
      content_tag(
        :div,
        lead_setting_view_service.auto_respond_status_text,
        class: "ui green label"
      )
    else
      content_tag(
        :div,
        lead_setting_view_service.auto_respond_status_text,
        class: "ui red label"
      )
    end
  end

  def display_auto_lead_forward_status(lead_setting_view_service)
    if lead_setting_view_service.email_auto_lead_forward_status_on?
      content_tag(
        :div,
        lead_setting_view_service.auto_lead_forward_status_text,
        class: "ui green label"
      )
    else
      content_tag(
        :div,
        lead_setting_view_service.auto_lead_forward_status_text,
        class: "ui red label"
      )
    end
  end

  def display_auto_lead_broadcast_status(lead_setting_view_service)
    if lead_setting_view_service.email_auto_lead_broadcast_status_on?
      content_tag(
        :div,
        lead_setting_view_service.auto_lead_broadcast_status_text,
        class: "ui green label"
      )
    else
      content_tag(
        :div,
        lead_setting_view_service.auto_lead_broadcast_status_text,
        class: "ui red label"
      )
    end
  end

  def display_lead_source_status_icon(parsing_from_source_active, size="huge")
    if parsing_from_source_active
      content_tag(:i, nil, class: "#{size} green check circle icon")
    else
      content_tag(:i, nil, class: "#{size} red remove icon")
    end
  end

end
