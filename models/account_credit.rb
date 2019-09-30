# == Schema Information
#
# Table name: account_credits
#
#  amount      :integer
#  created_at  :datetime         not null
#  description :string           not null
#  expires_at  :datetime
#  id          :bigint(8)        not null, primary key
#  redeemed    :boolean          default(FALSE)
#  redeemed_at :datetime
#  updated_at  :datetime         not null
#  user_id     :bigint(8)        not null
#
# Indexes
#
#  index_account_credits_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#

class AccountCredit < ActiveRecord::Base

  belongs_to :user

  validates :user_id, :description, presence: true

  def amount_in_dollar
    amount / 100
  end

end
