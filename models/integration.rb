# == Schema Information
#
# Table name: integrations
#
#  access_token       :string
#  account_id         :string
#  created_at         :datetime         not null
#  default_profile_id :string
#  email              :string
#  first_name         :string
#  id                 :bigint(8)        not null, primary key
#  last_name          :string
#  name               :string
#  refresh_token      :string
#  updated_at         :datetime         not null
#  user_id            :bigint(8)        not null
#
# Indexes
#
#  index_integrations_on_user_id  (user_id)
#

class Integration < ApplicationRecord

  belongs_to :user

end
