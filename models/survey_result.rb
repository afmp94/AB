# == Schema Information
#
# Table name: survey_results
#
#  access_code                       :string
#  agent_percentage_split            :decimal(, )
#  average_home_price                :integer
#  avg_commission_rate               :decimal(, )
#  bio_current                       :boolean
#  broker_code                       :string
#  broker_fee_alternative            :boolean
#  broker_fee_alternative_split      :decimal(, )
#  broker_fee_per_transaction        :integer
#  browser                           :string
#  buyer_touches                     :string
#  commission_split_type             :string
#  completed                         :boolean          default(FALSE)
#  contacts_grouped                  :string
#  contacts_ranked                   :boolean
#  created_at                        :datetime         not null
#  current_ytd_client_count          :integer
#  current_ytd_income                :integer
#  current_ytd_lead_count            :integer
#  daily_personal_marketing_effort   :string
#  daily_pipeline_review             :string
#  daily_tasks_set                   :string
#  desired_annual_income             :integer
#  drip_campaigns_to_followup        :string
#  email                             :string
#  est_business_expenses             :integer
#  feedback                          :text
#  feedback_score                    :integer
#  finished_at                       :datetime
#  first_name                        :string
#  follow_up_system                  :boolean
#  franchise_fee                     :boolean
#  franchise_fee_per_transaction     :decimal(, )
#  headshot_current                  :boolean
#  id                                :integer          not null, primary key
#  imported                          :boolean          default(FALSE)
#  last_name                         :string
#  lead_response_measurement         :string
#  lead_source_analysis              :boolean
#  listing_plan                      :string
#  local_service_list                :boolean
#  monthly_broker_fees_paid          :integer
#  monthly_email_newsletter_sent     :string
#  monthly_print_sent                :string
#  neighborhood_farming_cards_sent   :string
#  network_id                        :string
#  networking_meetings               :string
#  next_year_plans                   :string
#  office_code                       :string
#  online_profiles_current           :boolean
#  ordered_full_report               :boolean          default(FALSE)
#  other_work                        :text             default([]), is an Array
#  past_clients_touch                :string
#  past_year_income                  :integer
#  past_year_total_transaction       :integer
#  payment_status                    :integer          default(0), not null
#  pays_monthly_broker_fee           :boolean
#  per_transaction_fee_capped        :boolean
#  personal_marketing_plan           :string
#  platform                          :string
#  pre_made_marketing_plan           :string
#  profile_broker_pages_current      :boolean
#  promotion_code                    :string
#  quick_reaction_branding           :integer
#  quick_reaction_contacts           :integer
#  quick_reaction_goal_setting       :integer
#  quick_reaction_info               :integer
#  quick_reaction_lead_generation    :integer
#  quick_reaction_mass_marketing     :integer
#  quick_reaction_personal_marketing :integer
#  quick_reaction_service_clients    :integer
#  referer                           :string
#  referral_system                   :boolean
#  regular_service_reports           :boolean
#  seller_weekly_update              :boolean
#  size_of_database                  :string
#  social_media_engagement           :string
#  started_at                        :datetime
#  survey_token                      :string
#  system_for_transactions           :boolean
#  testimonials_current              :string
#  tracking_tool                     :string
#  transaction_fee_cap               :integer
#  updated_at                        :datetime         not null
#  use_crm                           :string
#  user_agent                        :string
#  user_id                           :integer
#  workload                          :string
#  years_experience                  :integer
#  zip_code                          :string
#
# Indexes
#
#  index_survey_results_on_access_code   (access_code)
#  index_survey_results_on_survey_token  (survey_token) UNIQUE
#  index_survey_results_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#

require "csv"

class SurveyResult < ActiveRecord::Base

  include VipList
  include SurveyResultsConstants

  has_secure_token :survey_token

  belongs_to :user

  # validates :first_name, :last_name, :email, presence: true
  # validates :email, format: AppConstants::EMAIL_REGEX

  before_validation :set_user_attributes, if: -> { user_id.present? }

  after_create :update_counter_in_referral_code

  before_save :clean_other_work

  def self.to_csv
    CSV.generate(headers: true) do |csv|
      csv << attribute_names

      find_each do |survey_result|
        csv << attribute_names.map { |attr| survey_result.send(attr) }
      end
    end
  end

  def to_param
    survey_token
  end

  def agent_percentage_split
    # NOTE: We need to handle 'nil' this in better way
    # May be to set dafault in the database if column is nil.
    self[:agent_percentage_split] || 0
  end

  def name
    [first_name, last_name].join(" ")
  end

  def free?
    payment_status == 3
  end

  def commission_rate
    avg_commission_rate || 2.5
  end

  def gross_commission
    puts "desired_annual_income: #{desired_annual_income}"
    puts "total_expenses: #{total_expenses}"
    puts "overall_agent_split_rate: #{overall_agent_split_rate}"
    (((desired_annual_income || 0 ) + (total_expenses || 0)) / overall_agent_split_rate) * 100
  end

  def gross_sales_volume
    gross_commission / commission_rate * 100
  end

  def estimated_number_of_sides
    gross_sales_volume / average_home_price
  end

  def annual_transaction_goal
    gross_sales_volume / average_home_price
  end

  def quarterly_transaction_goal
    annual_transaction_goal / 4
  end

  def monthly_transaction_goal
    annual_transaction_goal / 12
  end

  def total_expenses
    (est_business_expenses || 0) + ((monthly_broker_fees_paid || 0) * 12)
  end

  def average_gross_commission
    (commission_rate * average_home_price) / 100
  end

  def agent_fee_split
    (1 - broker_fee_per_transaction / average_gross_commission) * 100
  end

  def overall_agent_split_rate
    if franchise_fee
      puts "Has franchise fee.."
      case commission_split_type
      when "Percentage"
        (1 - franchise_fee_per_transaction / 100 ) * agent_percentage_split
      when "Fee"
        ((average_gross_commission * (1 - franchise_fee_per_transaction / 100) - broker_fee_per_transaction) / average_gross_commission) * 100
      else
        100
      end
    else
      case commission_split_type
      when "Percentage"
        agent_percentage_split
      when "Fee"
        agent_fee_split
      else
        100
      end
    end
  end

  # the following are the Activity Goals Calculations - any changes here should also be made in activity_goals_calculator.js.coffee

  def referrals_needed_per_month
    5 * monthly_transaction_goal
  end

  def communications_needed_per_month
    referrals_needed_per_month * 20
  end

  # Weekly Effort Calculation
  def suggested_total_weekly_effort
    communications_needed_per_month / 4.16
  end

  def suggested_calls_needed_per_week
    suggested_total_weekly_effort * 0.35
  end

  def suggested_note_required_per_week
    suggested_total_weekly_effort * 0.50
  end

  def suggested_visits_required_per_week
    suggested_total_weekly_effort * 0.15
  end

  # Daily Effort Calculation
  def suggested_total_daily_effort
    suggested_total_weekly_effort / 4
  end

  def suggested_calls_needed_per_day
    suggested_calls_needed_per_week / 4
  end

  def suggested_note_required_per_day
    suggested_note_required_per_week / 4
  end

  def suggested_visits_required_per_day
    suggested_visits_required_per_week / 4
  end

  def ordered_full_report!
    update!(ordered_full_report: true)
  end

  def mark_completed!
    update!(completed: true)
  end

  private

  def set_user_attributes
    if !free?
      self.email = user.email
      self.first_name = user.first_name
      self.last_name = user.last_name
    end
  end

  def update_counter_in_referral_code
    if access_code.present?
      referral_code = ReferralCode.find_by(code: access_code)
      referral_code&.increment!(:total_survey_taken_count)
    end
  end

  def clean_other_work
    other_work.reject!(&:blank?)
  end

end
