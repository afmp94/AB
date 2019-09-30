module ContactsHelper

  def next_contact_date_to_s(nextdate)
    if nextdate.nil?
      "N/A"
    elsif nextdate > Time.zone.now
      cal_date(nextdate)
    else
      "ASAP"
    end
  end

  def contact_activity_status_color(contact)
    last_contacted_date = contact.last_contacted_date
    grade = contact.grade
    if grade.nil? || last_contacted_date.nil? || grade == 4
      "neutral"
    else
      acceptable_days_between_touch = Contact::CONTACT_DAYS[grade.to_i] * 2 / 3
      days_since_last_touch = (Time.zone.now.to_date - last_contacted_date.to_date).to_i.days
      if days_since_last_touch > acceptable_days_between_touch
        "danger"
      elsif days_since_last_touch > acceptable_days_between_touch * 0.75
        "warning"
      else
        "success"
      end
    end
  end

  def format_display_name(contact, display_includes: %i(full_name email phone_number))
    formatted_values = []

    display_includes.each do |key|
      if (key == :phone_number)
        formatted_values << display_primary_phone_number(contact)
      else
        formatted_values << contact.public_send(key)
      end
    end

    formatted_display_name = formatted_values.map(&:presence).compact.first
    formatted_display_name = "Unknown" if formatted_display_name.blank?

    formatted_display_name
  end

  def contact_display_name(contact)
    format_display_name(contact, display_includes: %i(full_name email))
  end

  def time_since_last_contacted(contact)
    contact.last_contacted_date.nil? ? "Not yet contacted" : time_ago_in_words(contact.last_contacted_date) + " ago"
  end

  def display_contact_slats_data(contact)
    touches = contact.contact_activities.count
    if touches.positive?
      '<div class="data inline-block float-left">
        <h4>' + time_since_last_contacted(contact) + '</h4>
        <p class="dim-el">Last contacted</p>
      </div><!-- /data -->'
    else
      ""
    end
  end

  def display_primary_phone_number(contact)
    if contact&.phone_number.present?
      number_to_phone(contact.phone_number, area_code: true)
    else
      ""
    end
  end

  def display_primary_email_address(contact)
    contact&.email || ""
  end

  def basic_contact_info(contact)
    [
      display_primary_email_address(contact),
      display_primary_phone_number(contact)
    ].reject(&:blank?).join(" / ")
  end

  def lead_name(lead)
    contact = lead.contact

    return if contact.nil?

    contact.full_name.presence || display_primary_email_address(contact).presence ||
      display_primary_phone_number(contact).presence || "Unknown"
  end

  def format_phone_number(phone_number)
    formatted_phone_number = number_to_phone(phone_number.number, area_code: true)
    formatted_phone_number = "#{formatted_phone_number} (#{phone_number.number_type})"

    if phone_number.primary?
      formatted_phone_number = "#{formatted_phone_number} - <b>Primary</b>"
    end

    formatted_phone_number.html_safe
  end

  def format_email_address(email_address)
    formatted_email_address = email_address.email

    if email_address.email_type.present?
      formatted_email_address = "#{formatted_email_address} (#{email_address.email_type})"
    end

    if email_address.primary?
      formatted_email_address = "#{formatted_email_address} - #{content_tag(:b, 'Primary')}"
    end

    formatted_email_address.html_safe
  end

  def format_important_date(important_date)
    "#{important_date.name} (<strong>#{important_date.date_type}</strong>) "\
    "#{format_for_datepicker(important_date.date_at)}"
  end

  def grade_popover_circle(label)
    "<span class='initials-68 circle grade'>#{label}</span>"
  end

  def grade_tooltip(grade)
    if grade.zero?
      "B2B relations/multi-referrals"
    elsif grade == 1
      "Clients, Family & Friends that refer"
    elsif grade == 2
      "Folks you may have lost touch with"
    elsif grade == 3
      "Folks that may not know you're an Agent"
    elsif grade == 4
      "Exclude from Marketing - other agents/out of towners"
    else
      "Ranking Contacts helps keep in touch"
    end
  end

  def active_contacts_sorted_by_first_name(current_user)
    current_user.contacts.active.order("first_name asc")
  end

  def handle_required_validations(for_page)
    if ["lead"].include?(for_page)
      :require_base_validations
    else
      :require_basic_validations
    end
  end

  def group_name_label(group)
    "group=#{group.gsub(' ', '-').downcase}"
  end

  def unsubscribed_contact_info(contact)
    str = "Hi #{contact.name}"
    str = "#{str} (#{contact.email})" if contact.email.present?
    "#{str},"
  end

end
