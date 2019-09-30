# == Schema Information
#
# Table name: contact_groups_lists
#
#  created_at :datetime         not null
#  id         :bigint(8)        not null, primary key
#  list       :text             default([]), is an Array
#  updated_at :datetime         not null
#  user_id    :bigint(8)
#
# Indexes
#
#  index_contact_groups_lists_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class ContactGroupsList < ActiveRecord::Base

  belongs_to :user

end
