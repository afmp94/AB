class UpdateEmailCampaignsService

  def update_campaigns
    EmailCampaign.all.each do |email_campaign|
      unique_opens = 0
      unique_clicks = 0
      total_opens = 0
      total_clicks = 0
      delivery_count = 0
      email_campaign.campaign_messages.each do |message|
        if message.opens > 0
          unique_opens += 1
          total_opens += message.opens
        end
        if message.clicks > 0
          unique_clicks += 1
          total_clicks += message.clicks
        end
        if message.last_opened > email_campaign.last_opened
          email_campaign.last_opened = message.last_opened
        end
        if message.last_clicked > email_campaign.last_clicked
          email_campaign.last_clicked = message.last_clicked
        end
        if message.state == "sent"
          delivery_count += 1
        end
      end
      email_campaign.unique_opens = unique_opens
      email_campaign.total_opens = total_opens
      email_campaign.unique_clicks = unique_clicks
      email_campaign.total_clicks = total_clicks
      email_campaign.successful_deliveries = delivery_count
      email_campaign.save
    end
  end

end
