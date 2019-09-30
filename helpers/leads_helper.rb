module LeadsHelper

  def display_as_lead?(lead)
    lead.status.zero?
  end

  def display_as_client?(lead)
    lead.status != 0
  end

  def display_text_status(lead)
    if lead.status.zero?
      "lead"
    else
      "client"
    end
  end

  def time_active(lead)
    if lead.original_list_date_at
      if lead.status == 2 || lead.status == 3
        time_ago_in_words(lead.original_list_date_at)
      elsif lead.status == 4 && lead.displayed_closing_date_at
        distance_of_time_in_words(
          lead.original_list_date_at,
          lead.displayed_closing_date_at
        )
      else
        "-"
      end
    else
      "Not Set"
    end
  end

  def time_since_received(lead)
    time_received = lead.incoming_lead_at
    if time_received.nil?
      " - "
    else
      "#{distance_of_time_in_words(time_received, Time.zone.now)} ago"
    end
  end

  def display_lead_status_label(lead)
    state = lead.state
    if state.blank?
      ""
    else
      if state == "claimed"
        label_text = "Claimed"
        label_color = "success"
      else
        label_text = "Unclaimed"
        label_color = "danger"
      end
      '<div class="data inline-block float-left tlg">
        <h3><span class="label label-' + label_color + '"><strong>' + label_text + '</strong></span></h3>
      </div><!-- /data -->'
    end
  end

  def display_header_type(lead)
    case lead.status
    when 0
      "#{lead.client_type} Lead"
    when 1
      "#{lead.client_type} Prospect"
    when 2, 3, 4
      "#{lead.client_type} Client"
    when 5
      "Paused #{lead.client_type} - #{lead.stage_paused_to_s}"
    when 6
      "Not Converted #{lead.client_type} - #{lead.stage_lost_to_s}"
    when 7
      "Junk #{lead.client_type} Lead"
    when 8
      "Long Term Prospect #{lead.client_type} "
    end
  end

  def display_index_button_type(show_user_leads, current_status)
    if current_status == "8"
      "long_term_prospect"
    elsif show_user_leads == true
      "lead_all"
    else
      "current_pipeline"
    end
  end

  def display_label_on_button_type(show_user_leads, current_status)
    if current_status == "8"
      "Long Term Prospects"
    elsif show_user_leads == true
      "All"
    else
      "Current Pipeline"
    end
  end

  def contacted_status_to_color(lead)
    state = lead.state
    contacted_status = lead.contacted_status
    if state != "claimed"
      "negative"
    elsif contacted_status == 0
      "warning"
    elsif contacted_status == 1
      "warning"
    elsif contacted_status == 2
      "warning"
    elsif contacted_status == 3
      "positive"
    else
      "neutral"
    end
  end

  def display_contact_status(lead)
    state = lead.state
    contacted_status = lead.contacted_status
    if state != "claimed"
      "Unclaimed"
    elsif contacted_status == 0
      "Not Contacted"
    elsif contacted_status == 1
      "Attempted"
    elsif contacted_status == 2
      "Awaiting Client Response"
    elsif contacted_status == 3
      "Contacted"
    else
      " - "
    end
  end

  def formatted_lead_name(lead)
    contact = lead.contact

    return contact.full_name if contact.full_name.present?

    if display_primary_email_address(contact).present?
      return display_primary_email_address(contact).split("@")[0]
    end

    str = ""
    str = "#{lead.lead_source_to_s} " if lead.lead_source_to_s.present?
    str << display_primary_phone_number(contact)
    str
  end

  def elapsed_time_before_contacted(lead)
    received_at = lead.incoming_lead_at
    attempted_contact_at = lead.attempted_contact_at
    if received_at && attempted_contact_at
      distance_of_time_in_words(received_at, attempted_contact_at)
    else
      " - "
    end
  end

  def display_infobar_data(lead)
    render partial: "leads/infobars/slat_data", locals: { lead: lead }
  end

  def average_lead_response_time_in_words(user)
    time = user.average_new_lead_response_time
    if time
      distance_of_time_in_words(time)
    else
      " - "
    end
  end

  def lead_resolved_rate_past_week(user)
    if user.leads_referred_or_contact_attempted_in_past_week && user.leads_received_in_last_week.positive?
      user.leads_referred_or_contact_attempted_in_past_week * 100 / user.leads_received_in_last_week
    else
      0
    end
  end

  def lead_status_in_email(lead, user)
    if lead.state != "claimed"
      "This lead has not yet been claimed."
    elsif lead.user != user
      "This lead has been claimed by #{lead.user.name}."
    elsif lead.contacted_status.zero?
      "You claimed this lead."
    else
      "You claimed this lead and responded in #{elapsed_time_before_contacted(lead)}"
    end
  end

  def lead_recap_status(lead, user, leads_recap_service=nil)
    if lead.state != "claimed"
      "This lead has not been claimed."
    elsif lead.user == user
      if lead.status == 7
        "You claimed this lead and marked it as junk."
      elsif lead.contacted_status.zero?
        "You claimed this lead but have not replied yet."
      else
        "You claimed this lead and replied in #{time_length_in_words(leads_recap_service.avg_response_time)}."
      end
    elsif lead.status == 7
      "#{lead.user.name} claimed this lead and marked it as junk."
    elsif lead.contacted_status.zero?
      "#{lead.user.name} claimed this lead but has not replied yet."
    else
      "#{lead.user.name} claimed this lead and replied in "\
      "#{time_length_in_words(leads_recap_service.avg_response_time)}."
    end
  end

  def lead_recap_status_icon(lead, user)
    if lead.contacted_status != 0
      image_tag(
        "success_circle.png",
        align: "none",
        height: "35",
        style: "margin: 0px; border: 0; outline: none; text-decoration: none; -ms-interpolation-mode: bicubic; height: auto !important;",
        width: "35"
      )
    elsif lead.user != user
      image_tag(
        "warning_circle.png",
        align: "none",
        height: "35",
        style: "margin: 0px; border: 0; outline: none; text-decoration: none; -ms-interpolation-mode: bicubic; height: auto !important;",
        width: "35"
      )
    else
      image_tag(
        "alert_circle.png",
        align: "none",
        height: "35",
        style: "margin: 0px; border: 0; outline: none; text-decoration: none; -ms-interpolation-mode: bicubic; height: auto !important;",
        width: "35"
      )
    end
  end

  def status_board_row_highlight_class(lead)
    "negative" if lead.next_action.nil?
  end

  def show_lead_header_status_color(lead)
    if lead.contacted_status.zero?
      "red"
    elsif lead.contacted_status == 3
      "green"
    else
      "yellow"
    end
  end

  def lead_owner_name(lead)
    user = lead.user || lead.created_by_user

    if user == current_user
      content_tag(:span, "you", class: "fwb")
    else
      user.name
    end
  end

  def open_leads_sorted_by_name(current_user, include_team_leads=false)
    if include_team_leads
      current_user.team_leads.open_clients_and_leads.order("name asc")
    else
      current_user.leads.open_clients_and_leads.order("name asc")
    end
  end

  def lead_received_time_in_words(lead, with_source=false)
    if with_source && lead.lead_source_to_s.present?
      str = "#{time_since_received(lead)} from &nbsp "
      str << content_tag(:span, lead.lead_source_to_s, class: "fwb")
      str.html_safe
    else
      time_since_received(lead)
    end
  end

  def key_person_info(key_person)
    info = key_person.contact.full_name.titleize

    if key_person.contact.phone_number.present?
      info = "#{info} - #{key_person.contact.phone_number}"
    end

    info
  end

end
