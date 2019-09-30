# == Schema Information
#
# Table name: coaching_cards
#
#  action_label       :string
#  action_method      :string
#  action_path        :string
#  created_at         :datetime         not null
#  description        :text
#  id                 :bigint(8)        not null, primary key
#  locations          :string           default([]), is an Array
#  name               :string           not null
#  primary_module     :string
#  record_association :string
#  recurrence         :string
#  secondary_module   :string
#  send_email         :boolean          default(FALSE), not null
#  send_sms           :boolean          default(FALSE), not null
#  state              :string
#  subtitle           :string
#  title              :string           not null
#  trigger_model      :string           default("User"), not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_coaching_cards_on_name  (name) UNIQUE
#

class CoachingCard < ApplicationRecord

  has_many :coaching_messages, dependent: :destroy
  validates :name, presence: true, uniqueness: true
  validates :title, :trigger_model, presence: true

end
