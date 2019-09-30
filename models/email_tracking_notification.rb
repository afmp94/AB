# == Schema Information
#
# Table name: email_tracking_notifications
#
#  account_id          :string
#  clicked_urls        :string           is an Array
#  created_at          :datetime         not null
#  cursor_id           :string
#  email_message_id    :integer
#  event_id            :string
#  from_self           :boolean
#  id                  :bigint(8)        not null, primary key
#  metadata_id         :string
#  notification_at     :datetime
#  notification_type   :string
#  nylas_message_id    :string
#  recipient_email     :string
#  recipient_name      :string
#  reply_to_message_id :string
#  thread_id           :string
#  total_clicks        :integer
#  total_opens         :integer
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_email_tracking_notifications_on_email_message_id  (email_message_id)
#

class EmailTrackingNotification < ApplicationRecord

  belongs_to :email_message
  after_create :increment_trackings
  after_destroy :decrement_trackings

  TRACKING_ATTRIBUTES = ["opens", "clicks", "replied"]

  def opens_tracking?
    self.notification_type == "message.opened"
  end

  def clicks_tracking?
    self.notification_type == "message.link_clicked"
  end

  def replied_tracking?
    self.notification_type == "thread.replied"
  end

  private

  def increment_trackings
    action_plan_membership = self.email_message&.action_plan_membership || EmailMessage.find_by(
      message_id: self.reply_to_message_id
    )&.action_plan_membership

    TRACKING_ATTRIBUTES.each do |attribute|
      if action_plan_membership && self.send("#{attribute}_tracking?")
        action_plan_membership.increment!(attribute.to_sym)
      end
    end
  end

  def decrement_trackings
    action_plan_membership = self.email_message&.action_plan_membership || EmailMessage.find_by(
      message_id: self.reply_to_message_id
    )&.action_plan_membership

    TRACKING_ATTRIBUTES.each do |attribute|
      if action_plan_membership && self.send("#{attribute}_tracking?")
        action_plan_membership.decrement!(attribute.to_sym)
      end
    end
  end

end
