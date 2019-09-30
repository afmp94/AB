# == Schema Information
#
# Table name: action_plan_memberships
#
#  action_plan_id             :bigint(8)        not null
#  clicks                     :integer          default(0)
#  contact_id                 :bigint(8)        not null
#  created_at                 :datetime         not null
#  end_action_plan            :boolean          default(FALSE)
#  id                         :bigint(8)        not null, primary key
#  last_step_at               :datetime
#  last_step_id               :integer
#  lead_id                    :bigint(8)
#  lead_status_when_initiated :integer
#  next_step_at               :datetime
#  next_step_id               :integer
#  opens                      :integer          default(0)
#  replied                    :integer          default(0)
#  state                      :string
#  subscription_token         :string
#  updated_at                 :datetime         not null
#
# Indexes
#
#  index_action_plan_memberships_on_action_plan_id      (action_plan_id)
#  index_action_plan_memberships_on_contact_id          (contact_id)
#  index_action_plan_memberships_on_lead_id             (lead_id)
#  index_action_plan_memberships_on_subscription_token  (subscription_token) UNIQUE
#

class ActionPlanMembership < ApplicationRecord

  audited
  belongs_to :contact
  belongs_to :action_plan
  belongs_to :lead
  has_many :email_messages, dependent: :nullify
  validates :action_plan_id, :contact_id, presence: true
  before_save :set_step_attributes, if: Proc.new { |member| member.state_changed? && member.state != "completed" }
  scope :active, -> { where(state: "active") }
  scope :inactive, -> { where.not(state: "active") }
  scope :ready_to_execute, -> {
    where("next_step_at < ? and state = ? and end_action_plan = ?", Time.current, "active", false)
  }
  has_secure_token :subscription_token

  def contact_name
    contact.name
  end

  def contact_email
    contact.email
  end

  def next_step
    self.action_plan.action_plan_steps.find_by(id: self.next_step_id)
  end

  def last_step
    self.action_plan.action_plan_steps.find_by(id: self.last_step_id)
  end

  def set_step_attributes
    action_plan_step = self.action_plan.action_plan_steps.first
    self.next_step_id = action_plan_step.id
    next_send_date = Time.zone.parse(action_plan_step.send_time.to_s) || Time.zone.now
    if action_plan_step.delay_in_days.present?
      next_send_date = next_send_date + action_plan_step.delay_in_days.to_i.days
    end
    self.next_step_at = next_send_date
  end

  def replied?
    self.replied >= 1
  end

end
