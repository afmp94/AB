# == Schema Information
#
# Table name: action_plan_steps
#
#  action_plan_id             :bigint(8)        not null
#  created_at                 :datetime         not null
#  delay_in_days              :integer
#  email_template_id          :bigint(8)
#  id                         :bigint(8)        not null, primary key
#  notify_if_opened           :boolean          default(FALSE)
#  order                      :integer
#  require_approval           :boolean          default(FALSE)
#  reset_delay_if_interaction :boolean          default(FALSE)
#  send_time                  :string
#  step_type                  :string
#  track                      :boolean          default(TRUE)
#  updated_at                 :datetime         not null
#
# Indexes
#
#  index_action_plan_steps_on_action_plan_id     (action_plan_id)
#  index_action_plan_steps_on_email_template_id  (email_template_id)
#

class ActionPlanStep < ApplicationRecord

  belongs_to :action_plan
  belongs_to :email_template
  validates_associated :action_plan
  validates :email_template_id, presence: true
  default_scope { order(order: :asc) }

  def email_template_name
    email_template.name
  end

  def next
    action_plan.action_plan_steps.find_by(order: self.order + 1)
  end

end
