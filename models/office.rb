# == Schema Information
#
# Table name: offices
#
#  active          :boolean          default(TRUE)
#  created_at      :datetime         not null
#  id              :bigint(8)        not null, primary key
#  name            :string
#  organization_id :bigint(8)
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_offices_on_organization_id  (organization_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#

class Office < ActiveRecord::Base

  belongs_to :organization
  has_many :organization_members, dependent: :destroy do
    def active
      where(status: "active")
    end

    def inactive
      where(status: "inactive")
    end
  end

end
