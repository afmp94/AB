module EmailCampaigns::StatsHelper

  def calculate_contact_campaigns_open_percentage(messages)
    if messages.count > 0
      total = messages.count * 1.0 # convert to float
      open_count = 0
      messages.each do |message|
        if message.opens > 0
          open_count += 1
        end
      end
      (open_count / total) * 100
    else
      0
    end
  end

  def calculate_contact_campaigns_click_percentage(messages)
    if messages.count > 0
      total = messages.count * 1.0 # convert to float
      click_count = 0
      messages.each do |message|
        if message.clicks > 0
          click_count += 1
        end
      end
      (click_count / total) * 100
    else
      0
    end
  end

  def calculate_contact_total_campaign_opens(messages)
    if messages.count > 0
      total = 0
      messages.each do |message|
        total += message.opens
      end
      total
    else
      0
    end
  end

  def calculate_contact_total_campaign_clicks(messages)
    if messages.count > 0
      total = 0
      messages.each do |message|
        total += message.clicks
      end
      total
    else
      0
    end
  end

end
