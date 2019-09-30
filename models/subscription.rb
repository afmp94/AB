# == Schema Information
#
# Table name: subscriptions
#
#  account_balance               :float
#  card_expires_on               :date
#  card_last_four_digits         :string
#  card_type                     :string
#  created_at                    :datetime
#  deactivated_on                :date
#  id                            :integer          not null, primary key
#  next_payment_amount           :decimal(, )      default(0.0), not null
#  next_payment_on               :date
#  plan_id                       :integer          not null
#  plan_type                     :string           default("StandardPlan"), not null
#  scheduled_for_cancellation_on :date
#  stripe_id                     :string
#  trial_ends_at                 :datetime
#  updated_at                    :datetime
#  user_id                       :integer
#
# Indexes
#
#  index_subscriptions_on_plan_id    (plan_id)
#  index_subscriptions_on_stripe_id  (stripe_id)
#  index_subscriptions_on_user_id    (user_id)
#

class Subscription < ActiveRecord::Base

  belongs_to :plan, polymorphic: true
  belongs_to :user
  has_one :team_group, dependent: :destroy

  delegate :name, to: :plan, prefix: true
  delegate :stripe_customer_id, to: :user

  validates :plan_id, presence: true
  validates :plan_type, presence: true
  validates :user_id, presence: true

  def self.deliver_welcome_emails
    recent.each(&:deliver_welcome_email)
  end

  def self.canceled_in_last_30_days
    cancelled_within_period(30.days.ago, Time.zone.now)
  end

  def self.active_as_of(time)
    where("deactivated_on is null OR deactivated_on > ?", time)
  end

  def self.created_before(time)
    where("created_at <= ?", time)
  end

  def self.next_payment_in_2_days
    where(next_payment_on: 2.days.from_now)
  end

  def active?
    deactivated_on.nil?
  end

  def scheduled_for_cancellation?
    scheduled_for_cancellation_on.present?
  end

  def deactivate
    update_column(:deactivated_on, Time.zone.today)
  end

  def change_plan(sku:)
    if stripe_customer.sources.data.empty?
      return false
    end

    write_plan(sku: sku)
    change_stripe_plan(sku: sku)
  end

  def write_plan(sku:)
    self.plan = Plan.find_by!(sku: sku)
    save!
  end

  def change_stripe_plan(sku:)
    subscription = stripe_customer.subscriptions.first
    subscription.plan = sku
    subscription.save
  end

  def change_quantity(new_quantity)
    subscription = stripe_customer.subscriptions.first
    subscription.plan = plan.sku
    subscription.quantity = new_quantity
    subscription.save
  end

  def deliver_welcome_email
    SubscriptionMailer.welcome_to_jumpstart(user).deliver_now
  end

  def team_group?
    team_group.present?
  end

  def last_change
    Stripe::Charge.all(count: 1, customer: stripe_customer_id).first
  end

  def owner?(other_user)
    user == other_user
  end

  def next_payment_amount_in_dollars
    next_payment_amount / 100
  end

  def in_trial?
    trial_ends_at.present? && trial_ends_at > Time.current
  end

  def has_credit_card?
    card_last_four_digits.present?
  end

  private

  def self.cancelled_within_period(start_time, end_time)
    where(deactivated_on: start_time...end_time)
  end
  private_class_method :cancelled_within_period

  def self.active
    where(deactivated_on: nil)
  end
  private_class_method :active

  def self.recent
    where("created_at > ?", 24.hours.ago)
  end
  private_class_method :recent

  def users_for_analytics_tracking
    if team_group
      team_group.users
    else
      [user]
    end
  end

  def stripe_customer
    Stripe::Customer.retrieve(stripe_customer_id)
  end

end
