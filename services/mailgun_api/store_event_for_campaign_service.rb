class MailgunApi::StoreEventForCampaignService

  attr_reader :event_item

  def initialize(event_item)
    @event_item = event_item
  end

  def process
    event              = event_item["event"].downcase
    event_id           = event_item["id"]
    event_generated_at = Time.zone.at(event_item["timestamp"])
    message_id         = event_item["message"]["headers"]["message-id"]

    campaign_message = CampaignMessage.find_by(mailgun_id: message_id)

    if campaign_message.present?
      # Event id. It is guaranteed to be unique within a day. It can be used to
      # distinguish events that have already been retrieved when requests with
      # overlapping time ranges are made

      campaign_message_events = campaign_message.campaign_message_events

      if campaign_message_events.find_by(event_id: event_id, event_generated_at: event_generated_at).nil?
        campaign_message.campaign_message_events.create!(event_id: event_id,
                                                         event_type: event,
                                                         event_generated_at: event_generated_at)
      end
    end
  end

end
