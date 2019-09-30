# == Schema Information
#
# Table name: users
#
#  ab_email_address              :string           not null
#  account_marked_inactive_at    :datetime
#  address                       :string
#  agent_percentage_split        :decimal(, )
#  annual_broker_fees_paid       :decimal(, )
#  authentication_token          :string
#  avatar_color                  :integer          default(0)
#  billing_address               :string           default("")
#  billing_address_2             :string           default("")
#  billing_city                  :string           default("")
#  billing_country               :string           default("")
#  billing_email_address         :string           default("")
#  billing_first_name            :string           default("")
#  billing_last_name             :string           default("")
#  billing_organization          :string           default("")
#  billing_state                 :string           default("")
#  billing_zip_code              :string           default("")
#  broker                        :boolean          default(FALSE)
#  broker_fee_alternative        :boolean          default(FALSE)
#  broker_fee_alternative_split  :decimal(, )
#  broker_fee_per_transaction    :decimal(, )
#  broker_percentage_split       :decimal(, )
#  city                          :string
#  commission_split_type         :string
#  company                       :string
#  company_website               :string
#  confirmation_sent_at          :datetime
#  confirmation_token            :string
#  confirmed_at                  :datetime
#  contacts_count                :integer          default(0)
#  contacts_database_storage     :string
#  country                       :string
#  created_at                    :datetime
#  current_sign_in_at            :datetime
#  current_sign_in_ip            :string
#  dly_calls_counter             :integer          default(0)
#  dly_notes_counter             :integer          default(0)
#  dly_visits_counter            :integer          default(0)
#  email                         :string           default(""), not null
#  email_campaign_track_clicks   :boolean          default(TRUE)
#  email_campaign_track_opens    :boolean          default(TRUE)
#  email_signature               :text
#  email_signature_status        :boolean
#  encrypted_password            :string           default(""), not null
#  failed_attempts               :integer          default(0), not null
#  fax_number                    :string
#  first_name                    :string
#  franchise_fee                 :boolean          default(FALSE), not null
#  franchise_fee_per_transaction :decimal(, )
#  getting_started_video_watched :boolean          default(FALSE)
#  id                            :integer          not null, primary key
#  imported_google_contacts      :boolean          default(FALSE)
#  imported_nylas_contacts       :boolean          default(FALSE)
#  initial_setup                 :boolean          default(FALSE)
#  last_cursor                   :string
#  last_name                     :string
#  last_sign_in_at               :datetime
#  last_sign_in_ip               :string
#  lead_form_key                 :string
#  locked_at                     :datetime
#  mobile_number                 :string
#  monthly_broker_fees_paid      :decimal(, )
#  name                          :string
#  number_of_closed_leads_YTD    :integer          default(0)
#  nylas_account_id              :string
#  nylas_account_provider        :string
#  nylas_account_status          :string
#  nylas_calendar_setting_id     :string
#  nylas_connected_email_account :string
#  nylas_sync_status             :string
#  nylas_token                   :string
#  nylas_trial_status_set_at     :datetime
#  office_number                 :string
#  onboarding_completed          :boolean          default(FALSE), not null
#  per_transaction_fee_capped    :boolean          default(FALSE)
#  personal_website              :string
#  profile_pic                   :string
#  real_estate_experience        :string
#  remember_created_at           :datetime
#  reset_password_sent_at        :datetime
#  reset_password_token          :string
#  show_beta_features            :boolean          default(FALSE), not null
#  show_narrow_main_nav_bar      :boolean          default(FALSE)
#  sign_in_count                 :integer          default(0), not null
#  special_type                  :boolean          default(FALSE)
#  state                         :string
#  stripe_customer_id            :string
#  subscribed                    :boolean          default(FALSE)
#  super_admin                   :boolean          default(FALSE)
#  team_group_id                 :integer
#  team_id                       :integer
#  team_name                     :string
#  time_zone                     :string
#  transaction_fee_cap           :integer
#  twitter_secret                :string
#  twitter_token                 :string
#  ungraded_contacts_count       :integer          default(0)
#  unlock_token                  :string
#  updated_at                    :datetime
#  wkly_calls_counter            :integer          default(0)
#  wkly_notes_counter            :integer          default(0)
#  wkly_visits_counter           :integer          default(0)
#  zip                           :string
#
# Indexes
#
#  index_users_on_confirmation_token             (confirmation_token) UNIQUE
#  index_users_on_email                          (email) UNIQUE
#  index_users_on_last_cursor                    (last_cursor)
#  index_users_on_nylas_connected_email_account  (nylas_connected_email_account)
#  index_users_on_nylas_token                    (nylas_token)
#  index_users_on_reset_password_token           (reset_password_token) UNIQUE
#  index_users_on_stripe_customer_id             (stripe_customer_id)
#  index_users_on_team_group_id                  (team_group_id)
#  index_users_on_unlock_token                   (unlock_token) UNIQUE
#

class User < ActiveRecord::Base

  include AgentAssessment

  attr_accessor :reconfirmation_notification_needed, :skip_password_validation,
                :password_change_notification_required, :survey_result_token,
                :agent_token

  REAL_ESTATE_EXPERIENCE = {
    "50001" => "I'm brand new",
    "50002" => "0-2 years",
    "50003" => "2-5 years",
    "50004" => "5-10 years",
    "50005" => "10-20 years",
    "50006" => "20+ years",
  }.freeze

  CONTACTS_DATABASE_STORAGE = {
    "50001" => "Another real estate CRM",
    "50002" => "Google / Gmail",
    "50003" => "Outlook",
    "50004" => "My smartphone",
    "50005" => "Excel spreadsheet",
    "50006" => "Other",
    "50007" => "On paper or not stored digitally",
  }.freeze

  BASIC_URL_REGEX = /\A[A-Za-z0-9\.\/:]+[A-Za-z0-9_-]+\.+[A-Za-z0-9.\/%&=\?_:;-]+\z/i

  NYLAS_ACCOUNT_SYNC_STATUSES = {
    "account.invalid" => "Invalid",
    "account.running" => "Running",
    "account.connected" => "Connected",
    "account.stopped" => "Stopped"
  }

  KEY_FORMAT_REG = /[a-zA-Z0-9+\/]+/
  MIN_CONTACTS_FOR_INITIAL_SETUP = 5

  MAX_KEY_LENGTH                 = 7
  MAX_TRIES_TO_GENERATE_UNIQ_KEY = 7

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable
  devise(
    :async,
    :database_authenticatable,
    :omniauthable,
    :recoverable,
    :registerable,
    :confirmable,
    :rememberable,
    :trackable,
    :validatable,
    :timeoutable,
    :lockable,
    omniauth_providers: [:facebook, :twitter, :linkedin, :google_oauth2]
  )
  acts_as_tagger

  belongs_to :team_group
  has_and_belongs_to_many :lead_groups
  has_one :lead_setting, dependent: :destroy
  has_one :organization, foreign_key: :broker_id, inverse_of: :broker, dependent: :destroy
  has_one :profile_image, as: :attachable, class_name: "Image", dependent: :destroy
  has_one :team_owned, class_name: "Team", inverse_of: :owner, dependent: :destroy
  has_one :survey_result, dependent: :destroy
  has_one :twilio_phone_number, dependent: :destroy
  has_many :account_credits, dependent: :destroy
  has_many :authorizations, dependent: :destroy
  has_many :coaching_messages, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :contact_activities, dependent: :destroy
  has_one :contact_groups_list, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :contact_email_addresses, through: :contacts, source: :email_addresses
  has_many :contact_phone_numbers, through: :contacts, source: :phone_numbers
  has_many :contacts_created, class_name: "Contact", inverse_of: :created_by_user,
                              foreign_key: "created_by_user_id", dependent: :nullify
  has_many :csv_files, dependent: :destroy
  has_many :cursors, dependent: :destroy
  has_many :email_campaigns, dependent: :destroy
  has_many :email_messages, dependent: :destroy
  has_many :failed_api_imports, dependent: :destroy
  has_many :goals, dependent: :destroy
  has_many :images, dependent: :destroy
  has_many :nylas_messages, dependent: :destroy
  has_many :lead_groups_owned, class_name: "LeadGroup", inverse_of: :owner, dependent: :destroy
  has_many :leads, dependent: :destroy
  has_many :leads_created, class_name: "Lead", inverse_of: :created_by_user,
                           foreign_key: "created_by_user_id", dependent: :destroy
  has_many :read_message_broadcasts, dependent: :destroy
  has_many :organization_members, dependent: :destroy, foreign_key: :member_id
  has_many :personal_links, dependent: :destroy
  has_many :properties, dependent: :nullify
  has_many :campaign_messages, dependent: :nullify
  has_many :print_campaigns, dependent: :destroy
  has_many :print_campaign_messages, dependent: :nullify
  has_many :subscriptions, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :tasks_assigned, class_name: "Task", inverse_of: :assigned_to,
                            foreign_key: "assigned_to_id", dependent: :nullify
  has_many :tasks_completed, class_name: "Task", inverse_of: :completed_by,
                             foreign_key: "completed_by_id", dependent: :nullify
  has_many :teammates, dependent: :destroy
  has_many :teams, through: :teammates, dependent: :destroy
  has_many :dismissed_action_cards, dependent: :destroy
  has_many :survey_results, dependent: :destroy
  has_many :email_templates, dependent: :destroy
  has_many :action_plans, dependent: :destroy
  has_many :action_plan_memberships, through: :action_plans
  has_many :text_message_templates, dependent: :destroy
  has_many :integrations, dependent: :destroy
  has_many :dismissed_contacts, dependent: :destroy
  has_many :sms_messages, dependent: :nullify
  has_many :firebase_tokens, dependent: :nullify

  accepts_nested_attributes_for :profile_image, :goals

  scope :for_daily_overall_recap, ->(user_ids=nil) do
    joins(:subscriptions).where(subscriptions: { deactivated_on: nil }).joins(:lead_setting).where(
      lead_settings: {
        user_id: user_ids || self.all.map(&:id),
        daily_overall_recap: true
      }
    )
  end

  scope :for_receive_next_action_reminder_sms, ->(user_ids=nil) do
    joins(:lead_setting).where(
      lead_settings: {
        user_id: user_ids || self.all.map(&:id),
        next_action_reminder_sms: true
      }
    )
  end

  before_validation :set_user_name, on: :create
  before_validation :build_ab_email_address, on: :create
  before_validation :build_lead_form_key, on: :create
  before_validation :set_time_zone, on: :create

  before_save :ensure_authentication_token_is_present
  before_save :set_name

  after_create :build_lead_setting_for_user!, :set_avatar_background_color!,
               :update_survey_result, unless: :"special_type?"
  after_create :apply_account_credit!, if: -> { referral_code.present? }
  after_create :create_broker_organization!, if: -> { broker? }
  after_create :update_assessment_record

  before_update :handle_email_address_reconfirmation, unless: :"special_type?"

  after_update :send_reconfirmation_notification, unless: :"special_type?"

  delegate :plan, to: :subscription, allow_nil: true
  delegate :scheduled_for_cancellation_on, to: :subscription, allow_nil: true

  validates :first_name, :last_name, :ab_email_address, presence: true
  validates :lead_form_key, presence: true, uniqueness: true, format: { with: /\A#{KEY_FORMAT_REG}\Z/ }

  validates(
    :personal_website,
    format: { with: BASIC_URL_REGEX, message: "Please enter valid URL." },
    unless: Proc.new { |user| user.personal_website.blank? }
  )
  validates(
    :company_website,
    format: { with: BASIC_URL_REGEX, message: "Please enter valid URL." },
    unless: Proc.new { |user| user.company_website.blank? }
  )

  validates :mobile_number, :office_number, :fax_number, length: { minimum: 10, allow_blank: true }
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.us_zones.collect(&:name) }

  attr_accessor :referral_code

  def self.with_active_subscription
    includes(subscriptions: :plan, team_group: { subscription: :plan }).
      select(&:has_active_subscription?)
  end

  def self.subscriber_count
    Subscription.active.joins(team_group: :users).count +
      Subscription.active.includes(:team_group).where(team_groups: { id: nil }).count
  end

  def inactive_subscription
    if has_active_subscription?
      nil
    else
      most_recently_deactivated_subscription
    end
  end

  def create_subscription(plan:, stripe_id:, card_last_four_digits:, card_type:, card_expires_on:, trial_ends_at:)
    subscriptions.create(
      plan: plan,
      stripe_id: stripe_id,
      card_last_four_digits: card_last_four_digits,
      card_type: card_type,
      card_expires_on: card_expires_on,
      trial_ends_at: trial_ends_at
    )
  end

  def has_active_subscription?
    subscription.present?
  end

  def has_access_to?(feature)
    subscription.present? && subscription.has_access_to?(feature)
  end

  def subscribed_at
    subscription.try(:created_at)
  end

  def credit_card
    stripe_customer&.cards&.detect { |card| card.id == customer.default_card }
  end

  def plan_name
    plan.try(:name)
  end

  def team_group_owner?
    team_group.present? && team_group.owner?(self)
  end

  def subscription
    [personal_subscription, team_group_subscription].compact.detect(&:active?)
  end

  def eligible_for_annual_upgrade?
    plan.present? && plan.has_annual_plan?
  end

  def annualized_payment
    plan.annualized_payment
  end

  def discounted_annual_payment
    plan.discounted_annual_payment
  end

  def annual_plan_sku
    plan.annual_plan_sku
  end

  def deactivate_personal_subscription
    if personal_subscription
      Cancellation.new(subscription: personal_subscription).cancel.now
    end
  end

  def has_credit_card?
    stripe_customer_id.present?
  end

  def in_trial_without_card?
    has_active_subscription? &&
      !subscription.has_credit_card? &&
      subscription.in_trial?
  end

  def user_on_active_subscription_or_on_trial?
    has_active_subscription? || in_trial_without_card?
  end

  def trial_ends_at
    if has_active_subscription?
      subscription.trial_ends_at
    end
  end

  def has_connection_with?(provider)
    auth = self.authorizations.find_by(provider: provider)
    if auth.present?
      auth.token.present?
    else
      false
    end
  end

  def administrator?
    role.casecmp == "Administrator"
  end

  def not_administrator?
    !administrator?
  end

  def has_no_team_members?
    false
  end

  def full_name
    [first_name, last_name].map(&:presence).compact.join(" ")
  end

  def initials
    names = []

    names << first_name[0] if first_name.present?
    names << last_name[0] if last_name.present?

    names.join
  end

  def initial
    full_name[0]
  end

  def set_avatar_background_color!
    update!(avatar_color: Random.rand(12))
  end

  def next_notes
    (contacts.relationships.next_contacts_to_write_notes(Time.zone.today).
      time_since_last_activity(5.days).includes(:addresses).order("grade asc").
      order("next_note_at asc") - next_calls).
      first(number_of_activities_until_goal("Note"))
  end

  def next_calls
    contacts.relationships.next_contacts_to_call(Time.zone.today).
      time_since_last_activity(5.days).order("grade asc").
      order("next_call_at asc").limit(number_of_activities_until_goal("Call"))
  end

  def next_visits
    ((contacts.relationships.next_contacts_to_visit(Time.zone.today).
      time_since_last_activity(5.days).order("grade asc").
      order("next_visit_at asc") - next_calls) - next_notes).
      first(number_of_activities_until_goal("Visit"))
  end

  def closed_leads_ytd
    self.leads.closed_leads_after_date(Time.zone.now.beginning_of_year)
  end

  def closed_leads_for_year(year)
    leads.closed_leads_for_year(year)
  end

  def closed_team_leads_ytd
    team_leads.closed_leads_after_date(Time.zone.now.beginning_of_year)
  end

  def closed_leads_forecast_to_end_of_year
    self.leads.closed_leads_after_date(Time.zone.now.end_of_year)
  end

  def over_transaction_fee_cap?
    if per_transaction_fee_capped && transaction_fee_cap
      number_of_closed_leads_ytd >= transaction_fee_cap
    else
      false
    end
  end

  def broker_split
    if agent_percentage_split
      100 - agent_percentage_split
    end
  end

  def open_leads_count
    self.leads.lead_status.count
  end

  def not_contacted_leads_count
    Lead.leads_responsible_for(self).lead_status.leads_not_contacted.count
  end

  def display_image
    profile_image
  end

  def profile_image_url
    if profile_image
      profile_image.file.url
    else
      "https://placehold.it/180"
    end
  end

  def build_ab_email_address
    self.ab_email_address ||= generate_ab_email_address
  end

  def build_lead_form_key
    self.lead_form_key ||= generate_lead_form_key
  end

  def contacts_with_grade_count
    self.contacts.active.where("grade is not null").size
  end

  def mark_initial_setup_done!
    if contacts_with_grade_count >= MIN_CONTACTS_FOR_INITIAL_SETUP && goals_entered?
      update_attributes!(initial_setup: true)
    end
  end

  def goals_entered?
    if current_goal.nil?
      false
    elsif current_goal.note_required_wkly.nil? || current_goal.calls_required_wkly.nil? ||
          current_goal.visits_required_wkly.nil? || current_goal.note_required_wkly < 1
      false
    else
      true
    end
  end

  def set_user_name
    self.name ||= full_name
  end

  def set_name
    if first_name || last_name
      self[:name] = self.full_name
    end
  end

  def number_of_contacts
    active_contacts_count
  end

  def active_contacts_count
    contacts.active.count
  end

  def graded_contacts_count
    contacts.active.graded.count
  end

  def has_enough_graded_contacts?
    total_contacts = active_contacts_count

    total_contacts.positive? && (graded_contacts_count.to_f / total_contacts * 100).round(0) >= 40
  end

  def live_leads_count
    leads.live_leads.size
  end

  def first_email_campaign_sent
    if email_campaigns.empty?
      false
    else
      true
    end
  end

  def average_new_lead_response_time
    contacted_leads = leads.contacted_leads_with_dates
    contacted_leads_count = contacted_leads.count
    total_time = 0
    contacted_leads.each do |lead|
      total_time = total_time + (lead.attempted_contact_at - lead.incoming_lead_at)
    end
    if contacted_leads_count > 0
      total_time / contacted_leads_count
    end
  end

  def average_new_lead_response_time_past_week
    contacted_leads = leads.contacted_leads_with_dates.created_after_date(Time.zone.now - 7.days)
    contacted_leads_count = contacted_leads.count
    total_time = 0
    contacted_leads.each do |lead|
      total_time = total_time + (lead.attempted_contact_at - lead.incoming_lead_at)
    end
    if contacted_leads_count > 0
      total_time / contacted_leads_count
    end
  end

  # total number of clients that are prospect,active or pending
  def number_of_active_and_prospect_clients
    leads.client_current_pipeline_status.count
  end

  # total number of clients that are active or pending
  def number_of_active_clients
    leads.active_clients.count
  end

  # Total number of listings that are active or pending
  def number_of_active_listings
    leads.active_clients.listings.count
  end

  # Total number of buyers that are active or pending
  def number_of_active_buyers
    leads.active_clients.buyers.count
  end

  # Average list price for active, pending and closed with original listing date wthin last year
  def avg_list_price_last_12_months
    one_year_ago = Time.zone.now - 1.year
    active_and_closed_listings_with_price =
      leads.active_and_closed_clients.house_listing_after_date(one_year_ago).
        listings.where("original_list_price is not null")

    num_of_listings = active_and_closed_listings_with_price.count

    total_active_and_closed_listings_price = active_and_closed_listings_with_price.sum(:original_list_price)

    if num_of_listings > 0
      total_active_and_closed_listings_price / num_of_listings
    else
      0
    end
  end

  # Average sales price for closed listings within last 12 months
  def avg_sale_price_last_12_months
    one_year_ago = Time.zone.now - 1.year
    leads.closed_leads_after_date(one_year_ago).average(:displayed_price) || 0
  end

  # Average days on market report for listings that have been closed
  def avg_days_on_market
    one_year_ago = Time.zone.now - 1.year
    Util.log "one_year_ago is this: #{one_year_ago}"
    closed_ytd =
      leads.closed_leads_after_date(one_year_ago).
        where("original_list_date_at is not null AND displayed_closing_date_at is not null")
    if closed_ytd.count > 0
      total_time = 0
      closed_ytd.each do |lead|
        total_time = total_time + (lead.displayed_closing_date_at.to_date - lead.original_list_date_at.to_date)
      end
      total_time / closed_ytd.count
    else
      0
    end
  end

  # average days for listings closed within last 365 days
  def avg_days_to_closing
    one_year_ago = Time.zone.now - 1.year
    closed_ytd = leads.closed_leads_after_date(one_year_ago).
                   where("original_list_date_at is not null AND displayed_closing_date_at is not null")
    if closed_ytd.count > 0
      total_time = 0
      closed_ytd.each do |lead|
        total_time = total_time + (lead.displayed_closing_date_at.to_date - lead.original_list_date_at.to_date)
      end
      total_time / closed_ytd.count
    else
      0
    end
  end

  # TODO - displayed commission rate no longer exists
  # def avg_commission_rate
  #   closed_ytd = leads.closed_leads_after_date(Time.zone.now - 1.year).
  #                  listings.where("displayed_commission_rate is not null")
  #   if closed_ytd.count > 0
  #     closed_ytd.average(:displayed_commission_rate)
  #   else
  #     0
  #   end
  # end

  # Earned YTD Gross Commssion for an Agent

  def gross_commission_earned_ytd
    total_gross_commission_earned_ytd = 0
    closed_leads_ytd.each do |closed_lead|
      total_gross_commission_earned_ytd = total_gross_commission_earned_ytd + closed_lead.displayed_gross_commission
    end
    total_gross_commission_earned_ytd
  end

  def avg_lead_field_value(field)
    closed_ytd = leads.closed_leads_after_date(Time.zone.now - 1.year).where("#{field} is not null")
    if closed_ytd.count > 0
      closed_ytd.average(field)
    else
      0
    end
  end

  # Average Gross Commission for all Clients (buyers and sellers) within last year
  def avg_gross_commission
    self.avg_lead_field_value(:displayed_gross_commission)
  end

  # Average (Net)Commission for all Clients (buyers and sellers) within last year
  def avg_net_commission
    self.avg_lead_field_value(:displayed_net_commission)
  end

  # Sale to List Price

  def sale_to_list_price_cumulative
    one_year_ago = Time.zone.now - 1.year

    closed_ytd =
      leads.closed_leads_after_date(one_year_ago).
        where("original_list_price is not null AND displayed_price is not null")
    if closed_ytd.count > 0
      closed_ytd_original_list_price_total = 0
      closed_ytd_displayed_price_total = 0
      closed_ytd.each do |lead|
        closed_ytd_original_list_price_total = (closed_ytd_original_list_price_total + lead.original_list_price)
        closed_ytd_displayed_price_total = (closed_ytd_displayed_price_total + lead.displayed_price)
      end
      if closed_ytd_original_list_price_total > 0
        (closed_ytd_displayed_price_total / closed_ytd_original_list_price_total) * 100
      end
    else
      0
    end
  end

  # Pipeline Reporting Methods for displaying the Agents Client Stats

  def display_pipeline_status_total_house_value(status)
    leads.leads_by_status(status).sum(:displayed_price).to_i
  end

  def display_pipeline_status_total_net_commission(status)
    leads.leads_by_status(status).sum(:displayed_net_commission).to_i
  end

  def display_pipeline_status_count(status)
    leads.leads_by_status(status).count
  end

  def pipeline_current_closed_ytd_house_value
    closed_leads_ytd.sum(:displayed_price).to_i
  end

  def display_pipeline_closed_ytd_net_commission
    closed_leads_ytd.sum(:displayed_net_commission).to_i
  end

  def display_pipeline_closed_ytd_gross_commission
    closed_leads_ytd.sum(:displayed_gross_commission).to_i
  end

  def display_pipeline_closed_ytd_count
    closed_leads_ytd.count.to_i
  end

  def display_pipeline_closed_last_12_months
    one_year_ago = Time.zone.now - 1.year
    leads.closed_leads_after_date(one_year_ago).sum(:displayed_price).to_i
  end

  # Pipeline Reporting Methods for displaying the Agents Client Stats

  def belongs_to_team?
    user_has_teammates?
  end

  def display_projected_commission
    leads.client_current_pipeline_status.sum(:displayed_net_commission).to_i
  end

  def number_of_activities_until_goal(activity_type)
    if goals_entered?
      activities = (
        if activity_type == "Call"
          goals.last.daily_calls_goal - contact_activities.completed_today("Call").count
        elsif activity_type == "Note"
          goals.last.daily_notes_goal - contact_activities.completed_today("Note").count
        elsif activity_type == "Visit"
          goals.last.daily_visits_goal - contact_activities.completed_today("Visit").count
        else
          0
        end
      )
      if activities > 0
        activities
      else
        0
      end
    else
      5
    end
  end

  def build_lead_setting_for_user!
    if lead_setting.blank?
      build_lead_setting
      save!
    end
  end

  def update_survey_result
    if survey_result_token.present?  || self.email.present?
      survey_result = if survey_result_token.present?
                        SurveyResult.find_by(survey_token: survey_result_token)
                      else
                        SurveyResult.find_by(email: self.email)
                      end
      if survey_result.present?
        survey_result.user_id = self.id
        survey_result.save!

        import_service = SurveyResults::ImportService.new(survey_result.id)
        import_service.process
      end
    end
  end

  def update_assessment_record
    survey_result = SurveyResult.where(email: self.email).last
    if survey_result.present?
      survey_result.update(user_id: self.id)
    end
  end

  def make_agentbright_user!
    update!(special_type: false)
  end

  def set_trial_plan!
    plan = Plan.find_by(sku: "standard")
    checkout = plan.checkouts.build(
      user: self,
      email: email
    )
    checkout.fulfill
  end

  def make_agentbright_user_and_set_trial_plan!
    ActiveRecord::Base.transaction do
      make_agentbright_user!
      build_lead_setting_for_user!
      set_avatar_background_color!
      set_trial_plan!

      create_goal!

      if survey_result.created_at >= Time.zone.parse("September 1 2017")
        create_goal!(Time.current.year + 1)
      end
    end
  end

  def team_owned_by_user
    self.team_owned || self.team_owned = Team.create!
  end

  def team_member_ids
    member_ids = if self.team_owned
                   self.team_owned.approved_teammates.pluck(:id) << self.id
                 else
                   [self.id]
                 end
    member_ids.uniq
  end

  def team_member_ids_except_self
    if self.team_owned
      member_ids = self.team_owned.approved_teammates.map(&:id)
      member_ids&.uniq
    end
  end

  def user_has_teammates?
    return false if team_member_ids.nil?

    team_member_ids.count > 1
  end

  def team_leads
    Lead.owned_by_team_member(self.team_member_ids)
  end

  def team_tasks
    Task.owned_by_team_member(self.team_member_ids)
  end

  def team_tasks_assigned
    Task.assigned_to_team_member(self.team_member_ids)
  end

  def team_tasks_assigned_to_other_teammates
    Task.assigned_to_team_member(self.team_member_ids_except_self)
  end

  def has_nylas_token?
    nylas_token.present?
  end

  def lead_groups_owned_or_part_of
    (lead_groups + lead_groups_owned).flatten.uniq
  end

  def in_lead_group?
    !lead_groups_owned_or_part_of.empty?
  end

  def send_daily_overall_recap_email
    DailyRecapMailer.overall(id).deliver_now
  end

  def self.send_all_daily_overall_recap_emails
    User.for_daily_overall_recap.find_each(&:send_daily_overall_recap_email)
  end

  def self.send_all_next_action_reminder_sms_messages
    User.for_receive_next_action_reminder_sms.find_each do |user|
      if user.clients_without_next_action.present?
        user.send_next_action_reminder_sms
      end
    end
  end

  def send_next_action_reminder_sms
    payload = "AGENTBRIGHT: #{first_name}, you have "\
              "#{TextHelper.pluralize(clients_without_next_action.count, 'client', plural: 'clients')} "\
              "that don't have next actions set. Update them at "\
              "#{Rails.application.secrets.host}/#status-board"
    Util.log("Sending SMS: #{payload}")
    SmsService.new.dispatch(
      to: mobile_number,
      payload: payload
    )
  end

  def stripe_send_cancel_stripe_request_email
    StripeMailer.stripe_send_cancel_stripe_request_email(self.id).deliver_now
  end

  def leads_received_in_last_week
    Lead.owned_or_created_by_user(self).initially_leads.created_after_date(Time.zone.now - 7.days).count
  end

  def leads_referred_in_last_week
    Lead.leads_claimed_by_other_user(self).initially_leads.created_after_date(Time.zone.now - 7.days).count
  end

  def leads_referred_or_contact_attempted_in_past_week
    self.leads.initially_leads.created_after_date(Time.zone.now - 7.days).
      where("contacted_status <> 0 ").count + self.leads_referred_in_last_week
  end

  def open_leads_received_in_last_week
    # owner or created by user by not claimed or processed
    Lead.leads_responsible_for(self).lead_status.created_after_date(Time.zone.now - 7.days).count
  end

  def promoted_leads_received_in_last_week
    leads.initially_leads.clients_active_and_closed.created_after_date(Time.zone.now - 7.days).count
  end

  def junk_leads_received_in_last_week
    leads.initially_leads.leads_junk_status.created_after_date(Time.zone.now - 7.days).count
  end

  def not_converted_leads_received_in_last_week
    leads.initially_leads.leads_not_converted_status.created_after_date(Time.zone.now - 7.days).count
  end

  def rate_of_leads_contacted_in_under_30_minutes_in_past_week
    if leads_received_in_last_week > 0
      leads.created_after_date(Time.zone.now - 7.days).
        where("leads.contacted_status <> 0 AND leads.time_before_attempted_contact <= ?", 30.minutes).
        count / leads_received_in_last_week.to_f
    end
  end

  def activities_grouped_for_date(date)
    activities = activities_for_date(date)
    activities.group_by do |activity|
      I18n.l(activity.created_at.change(min: 0), format: :hours_mins_mer).upcase
    end
  end

  def activities_for_date(date)
    PublicActivity::Activity.
      where(
        "created_at >= ? AND created_at <= ?",
        date.beginning_of_day,
        date.end_of_day
      ).
      where(owner_id: team_member_ids).
      order("created_at ASC")
  end

  def in_quiet_hours?
    if quiet_hours_on?
      now = Time.zone.now.seconds_since_midnight
      seconds_per_hour = 3600.seconds
      start_time = lead_setting.quiet_hours_start * seconds_per_hour
      end_time = lead_setting.quiet_hours_end * seconds_per_hour

      result = between_start_and_end_hour?(now, start_time, end_time)
      Util.log(
        "start: #{lead_setting.quiet_hours_start}, end: "\
        "#{lead_setting.quiet_hours_end}, in_quiet_hours? #{result}"
      )
      result
    end
  end

  def quiet_hours_on?
    lead_setting.quiet_hours == true
  end

  def between_start_and_end_hour?(now, start_time, end_time)
    if start_time > end_time
      true unless now.between?(end_time, start_time)
    elsif end_time < start_time
      now.between?(start_time, end_time)
    end
  end

  def update_billing_information(first_name, last_name, email, organization,
                                 address, address_two, city, state, zip_code,
                                 country)
    self.update_attributes(
      billing_first_name: first_name,
      billing_last_name: last_name,
      billing_email_address: email,
      billing_organization: organization,
      billing_address: address,
      billing_address_2: address_two,
      billing_city: city,
      billing_state: state,
      billing_country: country,
      billing_zip_code: zip_code
    )
    self.save!
  end

  def update_billing_info_with_account_info
    self.update_attributes(
      billing_first_name: self.first_name,
      billing_last_name: self.last_name,
      billing_email_address: self.email,
      billing_organization: self.company,
      billing_address: self.address,
      billing_address_2: "",
      billing_city: self.city,
      billing_state: self.state,
      billing_country: self.country,
      billing_zip_code: self.zip
    )
    self.save!
  end

  def has_unread_billing_notifications?
    self.stripe_billing_notifications.where(read: false, stripe_event: "charge.failed").count > 0 ||
      self.stripe_billing_notifications.where(
        read: false,
        stripe_event: "customer.subscription.trial_will_end"
      ).count > 0 ||
      self.stripe_billing_notifications.where(
        read: false,
        stripe_event: "invoice.payment_failed"
      ).count > 0
  end

  def clients_without_next_action
    leads.client_current_pipeline_status.where(next_action: nil)
  end

  def team_clients_without_next_action
    team_leads.client_current_pipeline_status.where(next_action: nil)
  end

  def marketing_contact_activities
    contact_activities.where(activity_for: "marketing")
  end

  def team_or_solo_leads
    if user_has_teammates?
      team_leads
    else
      leads
    end
  end

  def leads_for_client_activity_recap(starttime)
    team_or_solo_leads.comments_or_tasks_updated_in_range(
      starttime,
      Time.current
    ).order("name asc")
  end

  def pending_csv_file?
    if csv_files.present? && (
      csv_files.order("csv_files ASC").last.state == "uploaded" ||
      csv_files.order("csv_files ASC").last.state == "processing"
    )
      true
    else
      false
    end
  end

  def contacts_data_in_json(query)
    @data = []

    return { success: true, results: @data } if query.blank?

    contact_ids = contacts.pluck(:id) | leads.pluck(:contact_id) |
                  Lead.owned_by_team_member(team_member_ids).pluck(:contact_id) |
                  Lead.leads_responsible_for(self).pluck(:contact_id)

    query = "%#{query}%"

    condition = ["contacts.id IN (?) AND (contacts.name ILIKE ? OR email_addresses.email ILIKE ?)",
                 contact_ids, query, query]

    Contact.includes(:email_addresses).where(condition).limit(4).references(:email_addresses).each do |c|
      c.email_addresses.each do |email_address|
        formatted_name = [c.name, email_address.email].reject(&:blank?).join(" - ")
        @data << { text: formatted_name, id: email_address.email }
      end
    end

    { success: true, results: @data }
  end

  def nylas_account_invalid?
    nylas_sync_status == NYLAS_ACCOUNT_SYNC_STATUSES["account.invalid"]
  end

  def nylas_account_valid?
    (nylas_sync_status == NYLAS_ACCOUNT_SYNC_STATUSES["account.running"]) ||
      (nylas_sync_status == NYLAS_ACCOUNT_SYNC_STATUSES["account.connected"])
  end

  def all_nylas_messages
    if has_nylas_token? && super_admin?
      NylasMessage.includes(:nylas_message_activities).all
    end
  end

  def mark_onboarding_completed!
    update!(onboarding_completed: true)
  end

  def total_account_credits_amount_in_cents
    account_credits.sum(&:amount)
  end

  def valid_account_credits
    account_credits.where("expires_at >= ? AND redeemed = ?", Time.current, false)
  end

  def has_any_unredeemed_account_credit?
    valid_account_credits.pluck(:redeemed).include? false
  end

  def update_subscription_account_balance(invoice)
    account_balance = subscription.account_balance
    if account_balance.present?
      account_balance -= invoice.total
      if account_balance.positive? || account_balance.zero?
        self.subscription.update!(account_balance: account_balance)
      end
    end
  end

  def create_goal!(year=nil)
    goals.create!(
      desired_annual_income: 0,
      est_business_expenses: 0,
      avg_price_in_area: 0,
      gross_commission_goal: 0,
      gross_sales_vol_required: 0,
      year: year
    )
  end

  def next_cards
    dismissed_card_ids = dismissed_action_cards.
                           where("dismissed_at IS NOT NULL").
                           pluck(:action_card_id)

    ActionCard.where(card_type: ActionCard::CARD_TYPES[:new_user]).
      where.not(id: dismissed_card_ids).order(:order)
  end

  def coaching_cards
    dismissed_card_ids = dismissed_action_cards.
                           where("dismissed_at IS NULL AND undismiss_at > ?", Time.current).
                           pluck(:action_card_id)

    ActionCard.where(card_type: ActionCard::CARD_TYPES[:coaching]).
      where.not(id: dismissed_card_ids).order(:order)
  end

  def branding_coaching_cards
    dismissed_card_ids = dismissed_action_cards.
                           where(
                             "(dismissed_at IS NOT NULL) OR (dismissed_at IS NULL AND undismiss_at > ?)",
                             Time.current
                           ).pluck(:action_card_id)

    ActionCard.
      where(card_type: ActionCard::CARD_TYPES[:coaching],
            sub_card_type: ActionCard::SUB_CARD_TYPES[:branding_coaching]).
      where.not(id: dismissed_card_ids).order(:order)
  end

  def relation_and_database_coaching_cards
    dismissed_card_ids = dismissed_action_cards.
                           where(
                             "(dismissed_at IS NOT NULL) OR (dismissed_at IS NULL AND undismiss_at > ?)",
                             Time.current
                           ).pluck(:action_card_id)

    ActionCard.
      where(card_type: ActionCard::CARD_TYPES[:coaching],
            sub_card_type: ActionCard::SUB_CARD_TYPES[:relation_and_database_coaching]).
      where.not(id: dismissed_card_ids).
      order(:order)
  end

  def personal_and_mass_marketing_coaching_cards
    dismissed_card_ids = dismissed_action_cards.
                           where(
                             "(dismissed_at IS NOT NULL) OR (dismissed_at IS NULL AND undismiss_at > ?)",
                             Time.current
                           ).pluck(:action_card_id)

    ActionCard.
      where(card_type: ActionCard::CARD_TYPES[:coaching],
            sub_card_type: ActionCard::SUB_CARD_TYPES[:personal_and_mass_marketing_coaching]).
      where.not(id: dismissed_card_ids).order(:order)
  end

  def lead_response_and_conversion_coaching_cards
    dismissed_card_ids = dismissed_action_cards.
                           where(
                             "(dismissed_at IS NOT NULL) OR (dismissed_at IS NULL AND undismiss_at > ?)",
                             Time.current
                           ).pluck(:action_card_id)

    ActionCard.
      where(card_type: ActionCard::CARD_TYPES[:coaching],
            sub_card_type: ActionCard::SUB_CARD_TYPES[:lead_response_and_conversion_coaching]).
      where.not(id: dismissed_card_ids).
      order(:order)
  end

  def service_management_coaching_cards
    dismissed_card_ids = dismissed_action_cards.
                           where(
                             "(dismissed_at IS NOT NULL) OR (dismissed_at IS NULL AND undismiss_at > ?)",
                             Time.current
                           ).pluck(:action_card_id)

    ActionCard.
      where(card_type: ActionCard::CARD_TYPES[:coaching],
            sub_card_type: ActionCard::SUB_CARD_TYPES[:service_management_coaching]).
      where.not(id: dismissed_card_ids).
      order(:order)
  end

  def self_and_business_management_coaching_cards
    dismissed_card_ids = dismissed_action_cards.
                           where(
                             "(dismissed_at IS NOT NULL) OR (dismissed_at IS NULL AND undismiss_at > ?)",
                             Time.current
                           ).pluck(:action_card_id)

    ActionCard.
      where(card_type: ActionCard::CARD_TYPES[:coaching],
            sub_card_type: ActionCard::SUB_CARD_TYPES[:self_and_business_management_coaching]).
      where.not(id: dismissed_card_ids).
      order(:order)
  end

  def current_goal
    goals.find_by(year: Time.current.year)
  end

  def all_contact_groups
    user_own_groups = []

    if contact_groups_list
      user_own_groups = contact_groups_list.list
    end
    user_own_groups + Contact::DEFAULT_GROUPS_LIST
  end

  def broker_commission_defined?
    commission_split_type.present? && (broker_split.present? || broker_fee_per_transaction.present?)
  end

  def clear_nylas_settings!
    update!(
      nylas_token: nil,
      nylas_account_id: nil,
      last_cursor: nil,
      nylas_connected_email_account: nil,
      nylas_sync_status: nil,
      nylas_calendar_setting_id: nil,
    )
  end

  def destroy
    leads_created.delete_all
    super
  end

  def email_templates_order_by_name
    email_templates.order("name asc")
  end

  protected

  def password_required?
    return false if skip_password_validation

    super
  end

  def send_password_change_notification?
    if password_change_notification_required.blank?
      return false
    end

    super
  end

  private

  def personal_subscription
    subscriptions.detect(&:active?)
  end

  def team_group_subscription
    if team_group.present?
      team_group.subscription
    end
  end

  def stripe_customer
    if stripe_customer_id.present?
      Stripe::Customer.retrieve(stripe_customer_id)
    end
  end

  def most_recently_deactivated_subscription
    [*subscriptions, team_group_subscription].
      compact.
      reject(&:active?).
      max_by(&:deactivated_on)
  end

  def generate_ab_email_address
    salt = SecureRandom.random_number(1000)

    # Removes non-alphanumeric characters.
    normalized_name = [first_name, last_name, salt].map(&:presence).
                        compact.join.downcase.gsub(/[^0-9a-z]/i, "")

    domain = Rails.application.secrets.leads[:agent_bright_me_email_domain]
    suffix_with_domain = domain.include?("@") ? domain : "@#{domain}"

    "#{normalized_name}#{suffix_with_domain}"
  end

  def generate_lead_form_key
    tries = MAX_TRIES_TO_GENERATE_UNIQ_KEY
    begin
      tries > 0 ? tries -= 1 : raise("Used max number of tries to generate new lead form key")
    end while User.exists?(lead_form_key: (key = random_lead_key))
    key
  end

  def random_lead_key
    # translates and removes -_= symbols from base64 representation string. Adapted from `Devise.friendly_token`
    SecureRandom.urlsafe_base64(MAX_KEY_LENGTH).downcase.tr("-_=", "pqr")
  end

  def set_time_zone
    self.time_zone ||= Rails.application.config.time_zone
  end

  def update_cursor
    nylas = NylasService.new(self.nylas_token)
    nylas.perform_delta_sync
  end

  def ensure_authentication_token_is_present
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.find_by(authentication_token: token)
    end
  end

  def handle_email_address_reconfirmation
    if changed_attribute_names_to_save.include?("email") &&
       reconfirmation_notification_needed == nil && confirmed_at.present?
      self.confirmed_at = nil
      self.reconfirmation_notification_needed = true
    end
  end

  def send_reconfirmation_notification
    if saved_change_to_attribute?("email") && reconfirmation_notification_needed == true
      clear_attribute_changes(["email"])
      self.reconfirmation_notification_needed = nil
      send_confirmation_instructions
    end
  end

  def apply_account_credit!
    referral_code_obj = ReferralCode.find_by(code: self.referral_code)

    if referral_code_obj.present? && !referral_code_obj.expired_for_account_credit?
      self.account_credits.create!(
        amount: referral_code_obj.account_credit_amount_in_cents,
        description: "Credit for #{self.name}",
        expires_at: Time.current + 30.days
      )
    end
  end

  def create_broker_organization!
    create_organization!(brokerage_name: "Untitled")
  end

end
