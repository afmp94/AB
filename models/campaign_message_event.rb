# == Schema Information
#
# Table name: campaign_message_events
#
#  campaign_message_id :integer
#  created_at          :datetime
#  event_generated_at  :datetime
#  event_id            :string
#  event_type          :string           default("")
#  id                  :integer          not null, primary key
#  ip                  :string           default("")
#  location            :string           default("")
#  ts                  :integer
#  ua                  :string           default("")
#  updated_at          :datetime
#  url                 :string
#
# Indexes
#
#  index_campaign_message_events_on_campaign_message_id  (campaign_message_id)
#

class CampaignMessageEvent < ActiveRecord::Base

  belongs_to :campaign_message

  scope :main_events, -> { where(event_type: ["opened", "clicked"]) }

end
