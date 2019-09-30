# == Schema Information
#
# Table name: email_templates
#
#  clicks                :integer          default(0), not null
#  created_at            :datetime         not null
#  id                    :bigint(8)        not null, primary key
#  message_body          :text
#  name                  :string
#  opens                 :integer          default(0), not null
#  purpose               :string
#  replies               :integer          default(0), not null
#  sends                 :integer          default(0), not null
#  subject               :string
#  updated_at            :datetime         not null
#  use_default_signature :boolean          default(FALSE)
#  user_id               :bigint(8)        not null
#
# Indexes
#
#  index_email_templates_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#

class EmailTemplate < ApplicationRecord

  validates :user_id, :name, :purpose, presence: true
  belongs_to :user
  has_many :action_plan_steps, dependent: :nullify

  CONTACT_DYNAMIC_FIELDS = [
    "First name",
    "Last name",
    "Title",
    "Company",
    "Email address",
    "Phone number"
  ].freeze

  def duplicate
    self.dup.tap do |i|
      i.name = "#{i.name} (copy)"
    end
  end

  def striped_message_body
    self.message_body.split("<br>").join(" ")
  end

end
