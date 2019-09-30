class LeadSettingViewService

  attr_reader :lead_setting
  attr_reader :user

  def initialize(lead_setting, user)
    @lead_setting = lead_setting
    @user = user
  end

  def display_label_for_auto_respond_action
    lead_setting.email_auto_respond? ? "Turn Off" : "Turn On"
  end

  def display_label_for_auto_lead_forward_action
    lead_setting.forward_lead_to_group? ? "Turn Off" : "Turn On"
  end

  def display_label_for_auto_lead_broadcast_action
    lead_setting.broadcast_lead_to_group? ? "Turn Off" : "Turn On"
  end

  def email_auto_lead_forward_status_on?
    lead_setting.forward_lead_to_group?
  end

  def email_auto_lead_broadcast_status_on?
    lead_setting.broadcast_lead_to_group?
  end

  def email_auto_respond_status_on?
    lead_setting.email_auto_respond?
  end

  def auto_respond_status_text
    lead_setting.email_auto_respond? ? "On" : "Off"
  end

  def auto_lead_forward_status_text
    lead_setting.forward_lead_to_group? ? "On" : "Off"
  end

  def auto_lead_broadcast_status_text
    lead_setting.broadcast_lead_to_group? ? "On" : "Off"
  end

  def lead_forward_status_information
    if lead_setting.forward_to_group.present? && lead_setting.forward_after_minutes.present?
      lead_forwarding_info = "<p>"
      lead_forwarding_info << "You have <strong>#{forward_after_minutes_text}</strong> to claim new leads."
      lead_forwarding_info << "<br/>After that, we will forward the "\
        "lead to <strong>#{lead_setting.forward_to_group.map(&:name).join(',')}</strong>."
      lead_forwarding_info << "</p>"
      lead_forwarding_info
    else
      ""
    end
  end

  def lead_broadcast_status_information
    if lead_setting.broadcast_to_group.present? && lead_setting.broadcast_after_minutes.present?
      lead_forwarding_info = "<p>"
      lead_forwarding_info << "we will automatically rebroadcast "\
        "leads to <strong>#{lead_setting.broadcast_to_group.map(&:name).join(',')}"\
        "</strong>"
      lead_forwarding_info << "<br/>if no one claims them within <strong>"\
        "#{broadcast_after_minutes_text}</strong>."
      lead_forwarding_info << "</p>"
      lead_forwarding_info
    else
      ""
    end
  end

  def forward_after_minutes_text
    if lead_setting.forward_after_minutes.nil?
      ""
    else
      LeadGroup::DURATION_BEFORE_LEAD_FORWARD.
        select { |_text, mins| mins == lead_setting.forward_after_minutes }.first.first
    end
  end

  def broadcast_after_minutes_text
    if lead_setting.broadcast_after_minutes.nil?
      ""
    else
      LeadGroup::DURATION_BEFORE_LEAD_BROADCAST.
        select { |_text, mins| mins == lead_setting.broadcast_after_minutes }.first.first
    end
  end

  # Todo: Generalize
  # Lead Source Status Methods

  def trulia_lead_source_count
    user.leads_created.lead_source_count(LeadSource.find_by(name: "Trulia").id)
  end

  def realtor_lead_source_count
    user.leads_created.lead_source_count(LeadSource.find_by(name: "Realtor.com").id)
  end

  def zillow_lead_source_count
    user.leads_created.lead_source_count(LeadSource.find_by(name: "Zillow").id)
  end

  def moxie_lead_source_count
    user.leads_created.lead_source_count(LeadSource.find_by(name: "Moxie").id)
  end

  def cinc_lead_source_count
    user.leads_created.lead_source_count(LeadSource.find_by(name: "CINC").id)
  end

  def parse_trulia_leads_status_text
    lead_setting.parse_trulia_leads? ? "Active" : "Inactive"
  end

  def parse_realtor_leads_status_text
    lead_setting.parse_realtor_leads? ? "Active" : "Inactive"
  end

  def parse_zillow_leads_status_text
    lead_setting.parse_zillow_leads? ? "Active" : "Inactive"
  end

  def display_label_for_trulia_leads_status
    lead_setting.parse_trulia_leads? ? "Turn Off" : "Turn On"
  end

  def display_label_for_zillow_leads_status
    lead_setting.parse_zillow_leads? ? "Turn Off" : "Turn On"
  end

  def display_label_for_realtor_leads_status
    lead_setting.parse_realtor_leads? ? "Turn Off" : "Turn On"
  end

  def parse_moxie_leads_status_text
    lead_setting.parse_moxie_leads? ? "Active" : "Inactive"
  end

  def display_label_for_moxie_leads_status
    lead_setting.parse_moxie_leads? ? "Turn Off" : "Turn On"
  end

  def parse_cinc_leads_status_text
    lead_setting.parse_cinc_leads? ? "Active" : "Inactive"
  end

  def display_label_for_cinc_leads_status
    lead_setting.parse_cinc_leads? ? "Turn Off" : "Turn On"
  end

end
