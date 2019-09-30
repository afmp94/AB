# == Schema Information
#
# Table name: text_message_templates
#
#  body       :text             not null
#  created_at :datetime         not null
#  id         :bigint(8)        not null, primary key
#  name       :string           not null
#  shared     :boolean          default(FALSE)
#  updated_at :datetime         not null
#  user_id    :bigint(8)
#
# Indexes
#
#  index_text_message_templates_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class TextMessageTemplate < ApplicationRecord

  belongs_to :user

  validates :name, :body, presence: true

  scope :owned_and_shared_with, ->(teammate_ids, user_id) { where("(text_message_templates.user_id IN (?) AND text_message_templates.shared = true) OR text_message_templates.user_id = ?", teammate_ids, user_id) }

end
