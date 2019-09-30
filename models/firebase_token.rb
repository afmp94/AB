# == Schema Information
#
# Table name: firebase_tokens
#
#  created_at  :datetime         not null
#  device_id   :string
#  device_type :string
#  fcm_token   :string
#  id          :bigint(8)        not null, primary key
#  updated_at  :datetime         not null
#  user_id     :bigint(8)
#
# Indexes
#
#  index_firebase_tokens_on_user_id  (user_id)
#

class FirebaseToken < ApplicationRecord

  belongs_to :user

  enum device_type: {
    android: "android",
    ios: "ios"
  }

end
