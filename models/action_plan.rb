# == Schema Information
#
# Table name: action_plans
#
#  allow_repeat_subscribers        :boolean          default(FALSE)
#  completed                       :integer          default(0)
#  created_at                      :datetime         not null
#  end_on_reply                    :boolean          default(FALSE)
#  id                              :bigint(8)        not null, primary key
#  include_unsubscribe             :boolean          default(FALSE)
#  name                            :string           not null
#  only_active_action_plan_allowed :boolean          default(FALSE)
#  open_rate                       :integer          default(0)
#  purpose                         :string           not null
#  scheduled                       :integer          default(0)
#  total_steps                     :integer          default(0)
#  updated_at                      :datetime         not null
#  user_id                         :bigint(8)        not null
#
# Indexes
#
#  index_action_plans_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#

class ActionPlan < ApplicationRecord

  belongs_to :user
  has_many :action_plan_steps, dependent: :destroy
  has_many :action_plan_memberships, dependent: :destroy

  scope :end_on_reply, -> { where(end_on_reply: true) }
  scope :has_active_memberships, -> do
    where(id: ActionPlanMembership.active.select(:action_plan_id))
  end

  validate :validate_steps
  validates :user_id, :name, :purpose, presence: true

  accepts_nested_attributes_for :action_plan_steps,
                                allow_destroy: true

  def step_count
    action_plan_steps.count
  end

  private

  def validate_steps
    i = 0
    action_plan_steps.each do |option|
      i += 1 unless option.marked_for_destruction?
    end
    errors.add(:base, "You must provide at least one step") if i < 1
  end

end
