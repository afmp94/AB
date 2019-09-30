# == Schema Information
#
# Table name: coaching_messages
#
#  cancelled_at     :datetime
#  coaching_card_id :bigint(8)        not null
#  completed_at     :datetime
#  created_at       :datetime         not null
#  dismissed_at     :datetime
#  id               :bigint(8)        not null, primary key
#  messageable_id   :bigint(8)
#  messageable_type :string
#  snoozed_at       :datetime
#  state            :string
#  unsnooze_at      :datetime
#  updated_at       :datetime         not null
#  user_id          :bigint(8)        not null
#
# Indexes
#
#  index_coaching_messages_on_coaching_card_id                     (coaching_card_id)
#  index_coaching_messages_on_messageable_type_and_messageable_id  (messageable_type,messageable_id)
#  index_coaching_messages_on_user_id                              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (coaching_card_id => coaching_cards.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#

class CoachingMessage < ApplicationRecord

  audited
  belongs_to :coaching_card
  belongs_to :user
  belongs_to :messageable, polymorphic: true

  delegate(
    :action_label,
    :action_path,
    :description,
    :locations,
    :subtitle,
    :title,
    to: :coaching_card
  )

  scope :active, -> { where(state: "active") }
  scope :for_location, ->(location) do
    joins(:coaching_card).where(":location = ANY(coaching_cards.locations)", location: location)
  end

  # rubocop:disable Style/HashSyntax, Metrics/BlockLength
  state_machine :state, initial: :active do
    state :dismissed
    state :cancelled
    state :completed
    state :snoozed

    event :complete! do
      transition any => :completed
    end

    event :dismiss! do
      transition any => :dismissed
    end

    event :cancel! do
      transition any => :cancelled
    end

    event :snooze! do
      transition any => :snoozed
    end

    event :unsnooze! do
      transition :snoozed => :active
    end

    before_transition all => :completed, do: :complete
    before_transition all => :dismissed, do: :dismiss
    before_transition all => :cancelled, do: :cancel
    before_transition all => :snoozed, do: :snooze
    before_transition :snoozed => :active, do: :unsnooze
  end
  # rubocop:enable Style/HashSyntax, Metrics/BlockLength

  def complete
    self.update!(completed_at: Time.current)
  end

  def dismiss
    self.update!(dismissed_at: Time.current)
  end

  def cancel
    self.update!(cancelled_at: Time.current)
  end

  def snooze
    self.update!(snoozed_at: Time.current, unsnooze_at: Time.current + 3.days)
  end

  def unsnooze
    self.update!(snoozed_at: nil, unsnooze_at: nil)
  end

end
