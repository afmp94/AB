# == Schema Information
#
# Table name: nylas_messages
#
#  clicked                         :boolean
#  clicks_tracking_id              :string
#  client_response_last_checked_at :datetime
#  contact_id                      :integer
#  created_at                      :datetime
#  id                              :integer          not null, primary key
#  lead_id                         :integer
#  nylas_message_id                :string
#  opened                          :boolean
#  opens_tracking_id               :string
#  sent_to_email_address           :string
#  updated_at                      :datetime
#  user_id                         :integer
#
# Indexes
#
#  index_nylas_messages_on_clicks_tracking_id     (clicks_tracking_id)
#  index_nylas_messages_on_contact_id             (contact_id)
#  index_nylas_messages_on_lead_id                (lead_id)
#  index_nylas_messages_on_nylas_message_id       (nylas_message_id)
#  index_nylas_messages_on_opens_tracking_id      (opens_tracking_id)
#  index_nylas_messages_on_sent_to_email_address  (sent_to_email_address)
#  index_nylas_messages_on_user_id                (user_id)
#

class NylasMessage < ApplicationRecord

  belongs_to :user
  belongs_to :contact
  belongs_to :lead
  has_many :nylas_message_activities, dependent: :destroy

end
