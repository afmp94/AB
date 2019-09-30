# == Schema Information
#
# Table name: organization_members
#
#  created_at      :datetime         not null
#  email_address   :string           not null
#  existing_user   :boolean          default(FALSE)
#  id              :bigint(8)        not null, primary key
#  member_id       :integer
#  office_id       :integer          not null
#  organization_id :integer          not null
#  status          :integer          not null
#  token           :string           not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_organization_members_on_member_id        (member_id)
#  index_organization_members_on_office_id        (office_id)
#  index_organization_members_on_organization_id  (organization_id)
#  index_organization_members_on_token            (token)
#
# Foreign Keys
#
#  fk_rails_...  (member_id => users.id)
#  fk_rails_...  (organization_id => organizations.id)
#

class OrganizationMember < ActiveRecord::Base

  enum status: %i(invited active inactive)

  has_secure_token

  belongs_to :office
  belongs_to :member, class_name: "User", foreign_key: :member_id
  belongs_to :organization

  validates :email_address, presence: true
  validates :email_address, format: AppConstants::EMAIL_REGEX
  validates :office_id, presence: true

  before_create :set_status, :check_exiting_user

  def self.activate_new_member!(member)
    organization_member = OrganizationMember.find_by(
      token: member.agent_token,
      existing_user: false,
      member_id: nil
    )

    organization_member.update!(member: member, status: "active")
  end

  def organization_owner
    organization.broker
  end

  private

  def set_status
    self.status = "invited"
  end

  def check_exiting_user
    self.existing_user = true if User.find_by(email: email_address).present?
  end

end
