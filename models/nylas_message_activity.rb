# == Schema Information
#
# Table name: nylas_message_activities
#
#  activity_event   :string
#  created_at       :datetime
#  id               :integer          not null, primary key
#  nylas_message_id :integer
#  ts               :datetime
#  updated_at       :datetime
#
# Indexes
#
#  index_nylas_message_activities_on_activity_event    (activity_event)
#  index_nylas_message_activities_on_nylas_message_id  (nylas_message_id)
#

class NylasMessageActivity < ApplicationRecord

  belongs_to :nylas_message

end
