# == Schema Information
#
# Table name: dismissed_contacts
#
#  contact_id :integer
#  created_at :datetime         not null
#  id         :bigint(8)        not null, primary key
#  updated_at :datetime         not null
#  user_id    :integer
#

class DismissedContact < ApplicationRecord

  belongs_to :user

end
