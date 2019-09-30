# == Schema Information
#
# Table name: twilio_phone_numbers
#
#  created_at    :datetime         not null
#  id            :bigint(8)        not null, primary key
#  sid           :string
#  twilio_number :string           not null
#  updated_at    :datetime         not null
#  user_id       :bigint(8)
#
# Indexes
#
#  index_twilio_phone_numbers_on_user_id  (user_id)
#

class TwilioPhoneNumber < ApplicationRecord

  belongs_to :user

  validates :twilio_number, presence: true

end
