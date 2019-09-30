# == Schema Information
#
# Table name: goals
#
#  agent_percentage_split            :decimal(, )
#  annual_transaction_goal           :decimal(, )
#  avg_commission_rate               :decimal(, )
#  avg_price_in_area                 :decimal(, )
#  broker_fee_alternative            :boolean          default(FALSE)
#  broker_fee_alternative_split      :decimal(, )
#  broker_fee_per_transaction        :decimal(, )
#  calls_required_wkly               :decimal(, )
#  commission_split_type             :string
#  contacts_need_per_month           :decimal(, )
#  contacts_to_generate_one_referral :decimal(, )      default(20.0)
#  created_at                        :datetime
#  daily_calls_goal                  :integer          default(0)
#  daily_notes_goal                  :integer          default(0)
#  daily_visits_goal                 :integer          default(0)
#  desired_annual_income             :decimal(, )
#  est_business_expenses             :decimal(, )
#  franchise_fee                     :boolean          default(FALSE), not null
#  franchise_fee_per_transaction     :decimal(, )
#  gross_commission_goal             :decimal(, )
#  gross_sales_vol_required          :decimal(, )
#  id                                :integer          not null, primary key
#  monthly_broker_fees_paid          :decimal(, )
#  monthly_transaction_goal          :decimal(, )
#  note_required_wkly                :decimal(, )
#  per_transaction_fee_capped        :boolean          default(FALSE)
#  portion_of_agent_split            :decimal(, )
#  qtrly_transaction_goal            :decimal(, )
#  referrals_for_one_close           :decimal(, )      default(5.0)
#  total_weekly_effort               :decimal(, )
#  transaction_fee_cap               :integer
#  updated_at                        :datetime
#  user_id                           :integer
#  visits_required_wkly              :decimal(, )
#  year                              :integer
#
# Indexes
#
#  index_goals_on_user_id           (user_id)
#  index_goals_on_user_id_and_year  (user_id,year) UNIQUE
#

class Goal < ActiveRecord::Base

  PRICE_FIELDS = [:desired_annual_income, :est_business_expenses, :gross_sales_vol_required, :avg_price_in_area, :gross_commission_goal]

  # This needs to be fixed. Only add validate false whenever required, not all the time.
  belongs_to :user, autosave: true, validate: false
  # validates_numericality_of PRICE_FIELDS

  before_save :calculate_daily_notes_goal
  before_save :calculate_daily_calls_goal
  before_save :calculate_daily_visits_goal

  accepts_nested_attributes_for :user

  after_initialize :init, if: :new_record?

  validates :year, presence: true, uniqueness: { scope: :user_id, message: "Goal is already present for this year" }

  default_scope { order(year: :desc) }
  scope :current, -> { where(year: Time.current.year) }

  def self.scrub_goal_price_fields(goal_params)
    PRICE_FIELDS.each do |price_field|
      price_value = goal_params[price_field].presence
      goal_params[price_field] = price_value.to_s.tr(",", "") if price_value.present?
    end
    goal_params
  end

  def net_commission_goal
    desired_annual_income + est_business_expenses
  end

  def calculate_daily_notes_goal
    self.daily_notes_goal = if note_required_wkly.nil?
                              0
                            else
                              (self.note_required_wkly / 4.0).ceil
                            end
  end

  def calculate_daily_calls_goal
    self.daily_calls_goal = if calls_required_wkly.nil?
                              0
                            else
                              (self.calls_required_wkly / 4.0).ceil
                            end
  end

  def calculate_daily_visits_goal
    self.daily_visits_goal = if visits_required_wkly.nil?
                               0
                             else
                               (self.visits_required_wkly / 4.0).ceil
                             end
  end

  def total_daily_referral_activities_goal
    calculate_daily_notes_goal
    calculate_daily_calls_goal
    calculate_daily_visits_goal
    daily_notes_goal + daily_calls_goal + daily_visits_goal
  end

  def current?
    Time.current.year == self.year
  end

  private

  def init
    self.year                          = Time.current.year if self.year.nil?

    self.desired_annual_income         = 0 if desired_annual_income.nil?
    self.est_business_expenses         = 0 if est_business_expenses.nil?
    self.avg_price_in_area             = 0 if avg_price_in_area.nil?
    # We set user's commision values to the goal object only for current year.
    if self.year == Time.current.year && user.present?
      self.monthly_broker_fees_paid      = user.monthly_broker_fees_paid
      self.franchise_fee                 = user.franchise_fee
      self.franchise_fee_per_transaction = user.franchise_fee_per_transaction
      self.commission_split_type         = user.commission_split_type
      self.agent_percentage_split        = user.agent_percentage_split
      self.broker_fee_per_transaction    = user.broker_fee_per_transaction
      self.broker_fee_alternative        = user.broker_fee_alternative
      self.broker_fee_alternative_split  = user.broker_fee_alternative_split
      self.per_transaction_fee_capped    = user.per_transaction_fee_capped
      self.transaction_fee_cap           = user.transaction_fee_cap
    end
  end

end
