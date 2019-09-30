# == Schema Information
#
# Table name: read_message_broadcasts
#
#  created_at           :datetime         not null
#  id                   :bigint(8)        not null, primary key
#  message_broadcast_id :bigint(8)
#  updated_at           :datetime         not null
#  user_id              :bigint(8)
#
# Indexes
#
#  index_read_message_broadcasts_on_message_broadcast_id  (message_broadcast_id)
#  index_read_message_broadcasts_on_user_id               (user_id)
#

class ReadMessageBroadcast < ActiveRecord::Base

  belongs_to :user
  belongs_to :message_broadcast

end
