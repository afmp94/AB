# == Schema Information
#
# Table name: message_broadcasts
#
#  created_at :datetime         not null
#  id         :bigint(8)        not null, primary key
#  title      :string
#  updated_at :datetime         not null
#
# Indexes
#
#  index_message_broadcasts_on_title  (title) UNIQUE
#

class MessageBroadcast < ActiveRecord::Base

  has_many :read_message_broadcasts, dependent: :destroy

  validates :title, presence: { uniqueness: true }

end
