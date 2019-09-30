# == Schema Information
#
# Table name: loops
#
#  created_at       :datetime         not null
#  id               :bigint(8)        not null, primary key
#  lead_id          :integer
#  loop_id          :integer
#  loop_url         :string
#  profile_id       :integer
#  status           :string
#  transaction_type :string
#  updated_at       :datetime         not null
#

class Loop < ApplicationRecord

  audited
  belongs_to :lead

end
