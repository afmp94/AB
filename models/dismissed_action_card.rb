# == Schema Information
#
# Table name: dismissed_action_cards
#
#  action_card_id :integer          not null
#  dismiss_type   :string
#  dismissed_at   :datetime
#  id             :bigint(8)        not null, primary key
#  undismiss_at   :datetime
#  user_id        :integer          not null
#
# Indexes
#
#  index_dismissed_action_cards_on_action_card_id  (action_card_id)
#  index_dismissed_action_cards_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (action_card_id => action_cards.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#

class DismissedActionCard < ActiveRecord::Base

  belongs_to :user
  belongs_to :action_card

  validates :user_id, :action_card_id, presence: true

end
