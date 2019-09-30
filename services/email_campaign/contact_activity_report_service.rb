class EmailCampaign::ContactActivityReportService

  attr_reader :email_campaign, :campaign_messages

  def initialize(email_campaign)
    @email_campaign = email_campaign
    @campaign_messages = email_campaign.campaign_messages
  end

  def opens_percentage
    if campaign_messages.count.positive?
      total = campaign_messages.count * 1.0 # convert to float

      return 100 if unique_opens_count == total

      (unique_opens_count / total).round(2)
    else
      0
    end
  end

  def clicks_percentage
    if campaign_messages.count.positive?
      total = campaign_messages.count * 1.0 # convert to float

      return 100 if unique_clicks_count == total

      (unique_clicks_count / total).round(2)
    else
      0
    end
  end

  def unique_opens_count
    options = { campaign_message_id: campaign_message_ids, event_type: "opened" }
    events  = CampaignMessageEvent.where(options)
    events  = events.select(:event_type, :campaign_message_id).distinct

    events.to_a.size
  end

  def unique_clicks_count
    options = { campaign_message_id: campaign_message_ids, event_type: "clicked" }
    events  = CampaignMessageEvent.where(options)
    events  = events.select(:event_type, :campaign_message_id). distinct

    events.to_a.size
  end

  def total_count_for(event_types)
    CampaignMessageEvent.where(campaign_message_id: campaign_message_ids,
                               event_type: event_types).count
  end

  def last_opened
    event_obj = CampaignMessageEvent.where(campaign_message_id: campaign_message_ids,
                                           event_type: "opened").order("id asc").last

    if  event_obj
      event_obj.event_generated_at.strftime("%B %d, %Y at %I:%M %p")
    else
      "Not yet opened"
    end
  end

  def last_clicked
    event_obj = CampaignMessageEvent.where(campaign_message_id: campaign_message_ids,
                                           event_type: "clicked").order("id asc").last

    if  event_obj
      event_obj.event_generated_at.strftime("%B %d, %Y at %I:%M %p")
    else
      "Not yet clicked"
    end
  end

  def recipient_list_name
    case email_campaign.recipient_selector_type
    when "grade"
      "Grades"
    when "group"
      "Groups"
    end
  end

  def recipient_list_data
    case email_campaign.recipient_selector_type
    when "grade"
      symbolic_selected_grades
    when "group"
      email_campaign.selected_groups
    end
  end

  def symbolic_selected_grades
    symbolic_grades = []

    email_campaign.selected_grades.each do |selected_grade|
      Contact::GRADES.each do |grade|
        if grade[1] == selected_grade
          symbolic_grades << grade[0]
        end
      end
    end

    symbolic_grades
  end

  def successful_deliveries_count
    total_count_for("delivered")
  end

  def avg_successful_deliveries
    campaign_message_count = email_campaign.campaign_messages.count
    delivred_count         = total_count_for("delivered")

    return 100 if delivred_count == campaign_message_count

    if delivred_count < campaign_message_count
      ((delivred_count.to_f / campaign_message_count.to_f) * 100).round(2)
    else
      0
    end
  end

  private

  def campaign_message_ids
    campaign_messages.pluck(:id)
  end

end
