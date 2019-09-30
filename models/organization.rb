# == Schema Information
#
# Table name: organizations
#
#  address        :text
#  broker_id      :integer
#  brokerage_name :string           not null
#  city           :string
#  country        :string
#  created_at     :datetime         not null
#  fax_number     :string
#  id             :bigint(8)        not null, primary key
#  phone_number   :string
#  state          :string
#  time_zone      :string
#  updated_at     :datetime         not null
#  website        :string
#  zip            :string
#
# Indexes
#
#  index_organizations_on_broker_id  (broker_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_id => users.id)
#

class Organization < ActiveRecord::Base

  belongs_to :broker, class_name: "User", inverse_of: :organization
  has_many :offices, dependent: :destroy
  has_many :organization_members, dependent: :destroy
  has_many :agents, through: :organization_members, source: :member_id

  validates :brokerage_name, presence: true

end
