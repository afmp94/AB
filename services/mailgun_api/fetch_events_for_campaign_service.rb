require "mailgun"

class MailgunApi::FetchEventsForCampaignService

  EVENTS = %w(
    delivered
    failed
    bounced
    complained
    opened
    clicked
  )

  attr_reader :mg_events

  def initialize
    mailgun_client = Mailgun::Client.new MAILGUN_API_KEY
    @mg_events = Mailgun::Events.new(mailgun_client, MAILGUN_DOMAIN)
  end

  def process
    begining_time = CampaignMessageEvent.order(:id).last.try(:created_at)
    begining_time = Time.current - 1.hour if begining_time.nil?

    result = mg_events.get({ "limit" => 300,
                             "begin" => begining_time.rfc2822,
                             "ascending" => "yes" })

    event_items = result.to_h["items"]

    return nil if event_items.empty?

    first_event_time = Time.zone.at(event_items.first["timestamp"]).to_datetime

    while begining_time < first_event_time do
      event_items.each do | item |
        if EVENTS.include?(item["event"].downcase)
          MailgunApi::StoreEventForCampaignService.new(item).process
        end
      end

      result      = mg_events.next
      event_items = result.to_h["items"]

      break if event_items.blank?

      first_event_time = Time.zone.at(event_items.first["timestamp"]).to_datetime
    end
  rescue Mailgun::CommunicationError => e
    Rails.logger.info "Mailgun::CommunicationError: #{e.message}"
  end

end
