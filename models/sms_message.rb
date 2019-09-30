# == Schema Information
#
# Table name: sms_messages
#
#  body       :text
#  contact_id :bigint(8)
#  created_at :datetime         not null
#  from       :string
#  id         :bigint(8)        not null, primary key
#  incoming   :boolean          default(FALSE)
#  sid        :text
#  to         :string
#  updated_at :datetime         not null
#  user_id    :bigint(8)
#
# Indexes
#
#  index_sms_messages_on_contact_id  (contact_id)
#  index_sms_messages_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#

class SmsMessage < ApplicationRecord

  audited

  include PublicActivity::Model
  tracked owner: proc { |_, sms| sms.incoming? ? sms.contact : sms.user },
          recipient: proc { |_, sms| sms.contact },
          associable: proc { |_, sms| sms.contact },
          params: {
            changes: :saved_changes,
            name: :body
          },
          on: { update: proc { |model, _| model.saved_changes.keys != ["updated_at"] } }

  belongs_to :user
  belongs_to :contact

  validates :sid, :to, :from, presence: true

  validates :body, presence: true, unless: :mms?

  has_many :images, as: :attachable, class_name: "Image", dependent: :destroy
  has_one :image, as: :attachable, class_name: "Image", dependent: :destroy

  delegate :name, to: :user, prefix: true, allow_nil: true
  delegate :name, to: :contact, prefix: true, allow_nil: true
  delegate :image_url, to: :image, allow_nil: true

  private

  def mms?
    image.present? || images.present?
  end

end
