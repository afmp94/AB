# == Schema Information
#
# Table name: campaign_messages
#
#  activity_ts_list  :string           default("")
#  clicks            :integer          default(0)
#  clicks_detail     :string           default("")
#  contact_id        :integer
#  created_at        :datetime
#  email_campaign_id :integer
#  id                :integer          not null, primary key
#  last_clicked      :integer          default(0)
#  last_opened       :integer          default(0)
#  mailgun_id        :string
#  opens             :integer          default(0)
#  opens_detail      :string           default("")
#  state             :string           default("0")
#  updated_at        :datetime
#  user_id           :integer
#
# Indexes
#
#  index_campaign_messages_on_contact_id         (contact_id)
#  index_campaign_messages_on_email_campaign_id  (email_campaign_id)
#  index_campaign_messages_on_mailgun_id         (mailgun_id)
#  index_campaign_messages_on_state              (state)
#  index_campaign_messages_on_user_id            (user_id)
#

class CampaignMessage < ActiveRecord::Base

  audited
  include RecentActivity

  belongs_to :user
  belongs_to :contact
  belongs_to :email_campaign
  has_many :campaign_message_events, dependent: :destroy

  include PublicActivity::Model
  include ActivityWatcher

  tracked owner: proc { |controller, _| controller&.current_user },
          recipient: proc { |_, campaign_message| campaign_message.contact },
          params: {
            changes: :activity_parameters_changes,
            name: proc { |_, campaign_message| campaign_message.email_campaign.title }
          },
          on: {
            update: proc do |campaign_message, _|
              campaign_message.savable_activity?(campaign_message.activity_parameters_changes)
            end
          }

end
