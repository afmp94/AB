# == Schema Information
#
# Table name: key_people
#
#  contact_id            :integer
#  created_at            :datetime         not null
#  id                    :bigint(8)        not null, primary key
#  lead_id               :integer
#  role_type             :string
#  sync_participant_role :boolean          default(FALSE)
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_key_people_on_contact_id  (contact_id)
#  index_key_people_on_lead_id     (lead_id)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id) ON DELETE => cascade
#  fk_rails_...  (lead_id => leads.id) ON DELETE => cascade
#

class KeyPerson < ActiveRecord::Base

  audited
  after_destroy :update_log_status

  ROLES = {
    buyer: "Buyer",
    seller: "Seller",
    buyer_agent: "Buyer's Agent",
    seller_agent: "Seller's Agent",
    buyer_attorney: "Buyer Attorney",
    inspector: "Inspector",
    appraiser: "Appraiser",
    other: "Other"
  }.freeze

  belongs_to :contact
  belongs_to :lead, touch: true

  validates :contact_id, :lead_id, :role_type, presence: true
  validate :unique_key_person, if: :required_resources_present?

  include PublicActivity::Model
  tracked(
    owner: proc { |controller, _| controller&.current_user },
    recipient: proc { |_, key_person| key_person.lead },
    associable_id: proc { |_, key_person| key_person.contact.id },
    associable_type: proc { |_, key_person| key_person.contact.class.name },
    params: { changes: :saved_changes, name: :name },
    on: { update: proc { |model, _| model.saved_changes.keys != ["updated_at"] } }
  )

  def name
    contact.name
  end

  private

  def unique_key_person
    if KeyPerson.where(lead_id: lead_id, contact_id: contact_id, role_type: role_type).exists?
      errors[:base] << "This key person is already present"
    end
  end

  def required_resources_present?
    lead.present? && contact.present?
  end

  def update_log_status
    key_person_log = KeyPersonLog.where(lead_id: self.lead_id, participant_id: self.id).last
    if !key_person_log.nil?
      key_person_log.update(is_deleted: true)
    end
  end

end
