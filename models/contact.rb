# == Schema Information
#
# Table name: contacts
#
#  active                                     :boolean          default(TRUE)
#  avatar_color                               :integer          default(0)
#  birthday                                   :string
#  company                                    :string
#  created_at                                 :datetime
#  created_by_user_id                         :integer
#  data                                       :hstore
#  email                                      :string
#  envelope_salutation                        :string
#  first_name                                 :string
#  google_api_contact_id                      :string
#  grade                                      :integer
#  graded_at                                  :datetime
#  id                                         :integer          not null, primary key
#  import_source_id                           :integer
#  import_source_type                         :string
#  inactive_at                                :datetime
#  ios_contact_id                             :integer
#  last_activity_at                           :datetime
#  last_called_at                             :datetime
#  last_contacted_at                          :datetime
#  last_name                                  :string
#  last_note_sent_at                          :datetime
#  last_visited_at                            :datetime
#  letter_salutation                          :string
#  merge_data                                 :string           default([]), is an Array
#  minutes_since_last_contacted               :integer
#  name                                       :string
#  next_activity_at                           :datetime
#  next_call_at                               :datetime
#  next_note_at                               :datetime
#  next_visit_at                              :datetime
#  phone_number                               :string
#  profession                                 :string
#  search_status                              :string
#  search_status_code                         :integer
#  search_status_message                      :string
#  spouse_first_name                          :string
#  spouse_last_name                           :string
#  subscription_token                         :string
#  suggested_facebook_url                     :string
#  suggested_first_name                       :string
#  suggested_googleplus_url                   :string
#  suggested_instagram_url                    :string
#  suggested_job_title                        :string
#  suggested_last_name                        :string
#  suggested_linkedin_bio                     :string
#  suggested_linkedin_url                     :string
#  suggested_location                         :string
#  suggested_organization_name                :string
#  suggested_twitter_url                      :string
#  suggested_youtube_url                      :string
#  suggestion_received                        :datetime
#  title                                      :string
#  total_received_messages_count              :integer
#  total_received_messages_count_in_past_year :integer
#  total_sent_messages_count                  :integer
#  total_sent_messages_count_in_past_year     :integer
#  unsubscribed                               :boolean          default(FALSE)
#  updated_at                                 :datetime
#  user_id                                    :integer
#  yahoo_contact_id                           :string
#
# Indexes
#
#  index_contacts_on_active                                 (active)
#  index_contacts_on_created_by_user_id                     (created_by_user_id)
#  index_contacts_on_email                                  (email)
#  index_contacts_on_grade                                  (grade)
#  index_contacts_on_ios_contact_id_and_created_by_user_id  (ios_contact_id,created_by_user_id) UNIQUE
#  index_contacts_on_name                                   (name)
#  index_contacts_on_phone_number                           (phone_number)
#  index_contacts_on_subscription_token                     (subscription_token) UNIQUE
#  index_contacts_on_user_id                                (user_id)
#  index_contacts_on_user_id_and_active_and_grade           (user_id,active,grade)
#

class Contact < ActiveRecord::Base

  audited
  CONTACT_DAYS        = { 0 => 30.days, 1 => 60.days, 2 => 90.days,
                          3 => 120.days, 4 => 120.days, 5 => 120.days }.freeze

  DEFAULT_GROUPS_LIST = [
    "Agent", "Appraiser", "Attorney", "B2B", "Business Owner", "Family",
    "Friend", "Home Inspector", "Insurance", "Mortgage Broker", "Past Client",
    "Sphere Of Influence"
  ].freeze

  GRADES              = [["A+", 0], ["A", 1], ["B", 2], ["C", 3], ["D", 4], ["-", 5]].freeze
  GRADES_IDS          = GRADES.collect { |_notation, id| id }.freeze
  PER_PAGE            = 25

  include ActivityWatcher
  include PublicActivity::Model
  include RecentActivity

  acts_as_taggable # Alias for acts_as_taggable_on :tags
  acts_as_taggable_on :contact_groups

  belongs_to :created_by_user, class_name: "User", inverse_of: :contacts_created
  belongs_to :import_source, polymorphic: true
  belongs_to :user, counter_cache: true
  has_many :addresses, as: :owner, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :contact_activities, dependent: :destroy
  has_many :email_addresses, as: :owner, dependent: :destroy
  has_many :campaign_messages, dependent: :destroy
  has_many :phone_numbers, as: :owner, dependent: :destroy
  has_many :important_dates, dependent: :destroy
  has_many :print_campaign_messages, dependent: :destroy
  has_many :leads
  has_many :referrals, class_name: "Lead", inverse_of: :referring_contact,
                       foreign_key: "referring_contact_id", dependent: :nullify

  has_many :key_people, dependent: :destroy
  has_many :tasks, as: :taskable, dependent: :destroy
  has_many :action_plan_memberships, dependent: :destroy
  has_many :sms_messages, dependent: :nullify

  has_one :api_suggested_image, as: :attachable, class_name: "Image", dependent: :destroy
  has_one :contact_image, as: :attachable, class_name: "Image", dependent: :destroy

  has_secure_token :subscription_token

  accepts_nested_attributes_for :api_suggested_image, :contact_image

  accepts_nested_attributes_for :addresses,
                                allow_destroy: true,
                                reject_if: :address_rejectable?

  accepts_nested_attributes_for :email_addresses,
                                allow_destroy: true,
                                reject_if: :email_address_rejectable?

  accepts_nested_attributes_for :phone_numbers,
                                allow_destroy: true,
                                reject_if: :phone_rejectable?

  accepts_nested_attributes_for :important_dates,
                                allow_destroy: true,
                                reject_if: :important_date_rejectable?

  attr_accessor :require_base_validations, :require_basic_validations,
                :typeahead_query_name, :required_salutations_to_set,
                :force_reload

  validates :grade, inclusion: { in: GRADES_IDS, allow_nil: true }
  validates :created_by_user_id, presence: true
  validate :base_validations, if: :require_base_validations?
  validate :basic_validations, if: :require_basic_validations?

  before_create :set_avatar_background_color

  before_save :set_name
  before_save :set_salutations, if: :required_salutations_to_set?
  before_save :set_force_reload, if: :reloading_needed?

  after_create :call_contact_api
  after_create :set_ungraded_contacts_count

  after_save :force_reload!, if: :force_reload_needed?
  after_save :handle_user_contact_groups

  after_update :handle_subscription_token
  after_update :set_ungraded_contacts_count_if_changed

  after_destroy :set_ungraded_contacts_count

  scope :active, -> { where(active: true) }
  scope :by_grade, ->(grade) { where("grade = ?", grade) }
  scope :by_user_and_email, ->(user, email) do
    joins(:email_addresses).where(user: user).where("email_addresses.email = ? ", email)
  end

  scope :for_daily_recap, ->(today) do
    relationships.where("(DATE(next_call_at) <= :today OR next_call_at is NULL) OR " \
                        "(DATE(next_note_at) <= :today OR next_note_at is NULL) OR " \
                        "(DATE(next_visit_at) <= :today OR next_visit_at is NULL)",
                        today: today)
  end

  scope :grad_a_plus, -> { where(grade: 0) }
  scope :grad_a_plus_abc, -> { where("grade in (0,1,2,3)") }
  scope :graded, -> { where.not(grade: nil) }
  scope :graded_for, ->(grades) { where(grade: grades) }
  scope :next_contacts_to_call, ->(today) { where("next_call_at <= ? OR next_call_at is null", today) }
  scope :next_contacts_to_write_notes, ->(today) { where("next_note_at <= ? OR next_note_at is null", today) }
  scope :next_contacts_to_visit, ->(today) { where("next_visit_at <= ? OR next_visit_at is null", today) }
  scope :records_for_minutes_since_last_contacted, ->(minutes) { where("minutes_since_last_contacted >= ?", minutes) }
  scope :relationships, -> { where("grade <= ?", 3) }
  scope :search_name, ->(search_term) do
    search_term = (search_term.presence || "").strip
    where("CONCAT_WS(' ', first_name, last_name) ILIKE :search_term", search_term: "%#{search_term}%")
  end
  scope :time_since_last_activity, ->(time) do
    where("last_activity_at <= ? OR last_activity_at is null", (Time.current - time))
  end
  scope :ungraded, -> { where(grade: nil) }
  scope :selectable_contacts, ->(action_plan) do
    where.not(id: action_plan.action_plan_memberships.where(state: :active).pluck(:contact_id)).order("first_name asc")
  end

  tracked(
    owner: proc { |controller, _contact| controller&.current_user },
    recipient: proc { |_controller, contact| contact },
    params: {
      changes: :activity_parameters_changes,
      name: :full_name
    },
    on: {
      update: proc do |model, _|
        model.savable_activity?(model.activity_parameters_changes)
      end
    }
  )

  recent_activities_for(
    self: {
      attributes: [
        :company,
        :envelope_salutation,
        :first_name,
        :grade,
        :last_name,
        :spouse_first_name,
        :title
      ]
    },
    associations: {
      addresses: { attributes: [:city, :state, :street, :zip] },
      email_addresses: { attributes: [:email, :email_type] },
      phone_numbers: { attributes: [:number, :number_type] }
    }
  )

  extend_recent_activities_for(
    sms_messages: {
      condition: ->(contact) do
        {
          recipient_id: contact.id,
          recipient_type: contact.class.to_s,
          key: ["sms_message.create"]
        }
      end
    },
    comments: {
      condition: ->(contact) do
        {
          recipient_id: contact.id,
          recipient_type: contact.class.to_s,
          key: ["comment.create", "comment.destroy"]
        }
      end
    },
    contact_activities: {
      condition: ->(contact) do
        {
          recipient_id: contact.id,
          recipient_type: contact.class.to_s,
          key: [
            "contact_activity.create",
            "contact_activity.destroy",
            "contact_activity.update"
          ]
        }
      end
    },
    campaign_message: {
      condition: ->(contact) do
        {
          recipient_id: contact.id,
          recipient_type: contact.class.to_s,
          key: ["campaign_message.create"]
        }
      end
    },
    tasks: {
      condition: ->(contact) do
        {
          recipient_id: contact.id,
          recipient_type: contact.class.to_s,
          key: ["task.create", "task.complete", "task.destroy", "task.update"]
        }
      end
    }
  )

  def name
    # If contact's name is nil, then fetch name from the full_name method.
    self[:name] || full_name
  end

  def set_name
    if first_name || last_name
      self[:name] = self.full_name
    end
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

  def set_avatar_background_color
    self.avatar_color = Random.rand(12)
  end

  def display_image
    if contact_image
      contact_image
    elsif api_suggested_image
      api_suggested_image
    end
  end

  def grade_to_s
    grade.nil? ? " ? " : GRADES[grade][0]
  end

  def last_activity_completed
    contact_activities.order("completed_at asc").last
  end

  def last_activity_completed_by_type(type)
    contact_activities.activities_by_type(type).order("completed_at asc").last
  end

  def last_called_at_to_s
    last_called_at.nil? ? "No calls made" : last_called_at.to_date.to_s(:cal_date)
  end

  def last_note_sent_at_to_s
    last_note_sent_at.nil? ? "No notes written" : last_note_sent_at.to_date.to_s(:cal_date)
  end

  def last_visited_at_to_s
    last_visited_at.nil? ? "No visits" : last_visited_at.to_date.to_s(:cal_date)
  end

  def self.mass_grade_update(ids, grade)
    where(id: ids).update_all(grade: grade, updated_at: Time.current)
  end

  def self.update_groups(groups)
    find_each do |contact|
      contact.user.tag(contact, with: groups.join(", "), on: :contact_groups)
      contact.touch(:updated_at)
    end
  end

  def self.random_ungraded_contact(exclude_contact_id=nil)
    ungraded_contact = Contact.ungraded
    if exclude_contact_id
      ungraded_contact = ungraded_contact.where.not(id: exclude_contact_id)
    end
    ungraded_contact.order("random()").first
  end

  def set_ungraded_contacts_count
    if self.user
      ungraded_contacts_count = user.contacts.active.ungraded.count
      self.user.update!(ungraded_contacts_count: ungraded_contacts_count)
    end
  end

  def set_ungraded_contacts_count_if_changed
    # NOTE: 'ungraded_contacts_count' column should get updated when contacts
    # 'grade' column gets changed as well as 'active' column gets changed.

    if self.user && (self.saved_changes.keys.include?("grade") || self.saved_changes.keys.include?("active"))
      self.user.update!(ungraded_contacts_count: self.user.contacts.active.ungraded.count)
    end
  end

  def last_contacted_date
    [last_note_sent_at, last_called_at, last_visited_at].compact.max
  end

  def next_contact_date
    [next_note_at, next_call_at, next_visit_at].compact.min
  end

  def number_of_touches_ytd
    contact_activities.year_to_date.count
  end

  def primary_phone_number
    phones = phone_numbers.order("created_at ASC")
    phones.find_by(primary: true) || phones.first
  end

  def primary_email_address
    emails = email_addresses.order("created_at ASC")
    emails.find_by(primary: true) || emails.first
  end

  def primary_address
    addresses.first
  end

  def all_emails
    email_addresses.pluck(:email)
  end

  def touch_frequency
    activities_for_contact = contact_activities.completed_this_year
    if activities_for_contact.count > 1
      activities_ordered_by_date = activities_for_contact.order("completed_at asc")
      first_activity_date = activities_ordered_by_date.first.completed_at
      (Time.current.to_date - first_activity_date.to_date).to_i / (activities_for_contact.count - 1)
    else
      0
    end
  end

  def transactions
    transactions = []

    leads.find_each do |lead|
      name = if lead.client_type == "Seller"
               lead.client_type
             else
               "#{lead.listing_address_street} #{lead.listing_address_city} (#{lead.client_type})"
             end

      transaction                            = {}
      transaction[:id]                       = lead.id
      transaction[:name]                     = name
      transaction[:status]                   = Lead::STATUSES[lead.status][0]
      transaction[:displayed_price]          = lead.displayed_price
      transaction[:displayed_net_commission] = lead.displayed_net_commission
      transaction[:displayed_closing_date_at] = lead.displayed_closing_date_at

      transactions << transaction
    end

    transactions
  end

  def contact_groups_by_user(user)
    contact_groups_from(user)
  end

  def not_selected_contact_groups_by_user(user)
    user.all_contact_groups - contact_groups_from(user)
  end

  def mark_as_inactive!
    self.active = false
    self.inactive_at = Time.current
    save!
  end

  def self.find_from_email(user, email)
    user.contacts.joins(:email_addresses).find_by(email_addresses: { email: email })
  end

  def call_contact_api
    if Rails.env != "rake"
      Contact.delay(priority: 20).call_fullcontact_api(self.id)
    end
  end

  def refresh_contact_api_info
    FullContactInfoUpdater.new(self.id).update_all_and_save
  end

  def self.call_fullcontact_api(id)
    FullContactInfoUpdater.new(id).update_all_and_save
  end

  def call_nylasapp(token)
    Util.log "Token: #{token}"
    primary_email = self.primary_email_address
    if primary_email && token
      email_address = primary_email.email
      NylasApi::Thread.new(token: token).find_by_email_address(email_address)
    end
  end

  def fetch_email_messages(token)
    if all_emails.present? && token
      NylasApi::Message.new(token: token).find_by_email_addresses(all_emails)
    end
  end

  def social_info_present?
    [suggested_first_name, suggested_last_name,
     suggested_location, suggested_organization_name,
     suggested_job_title, suggested_linkedin_bio,
     suggested_facebook_url, suggested_linkedin_url,
     suggested_twitter_url, suggested_googleplus_url,
     suggested_instagram_url, suggested_youtube_url].select(&:present?).any?
  end

  def has_a_valid_primary_email_address?
    primary_email = self.primary_email_address
    if primary_email
      email_address = primary_email.email
      if email_address
        ValidateEmail.valid?(email_address)
      else
        false
      end
    else
      false
    end
  end

  def received_email_messages
    user.email_messages.where(
      "from_email = ? AND ? = ANY (to_email_addresses)",
      user.nylas_connected_email_account,
      email
    )
  end

  def received_email_messages_total_count
    received_email_messages.count
  end

  def received_email_messages_in_last_year_count
    received_email_messages.where("received_at >= ?", 1.year.ago.beginning_of_day).count
  end

  def last_received_email_sent_at
    received_email_messages.maximum(:received_at)
  end

  def overall_last_contacted_at
    [last_received_email_sent_at, last_contacted_date].compact.max
  end

  def received_email_messages_total_count_from_nylas
    return @total_received_count if @total_received_count.present?

    from = user.nylas_connected_email_account
    to   = email
    @total_received_count = nylas_message_object.total_count(from: from, to: to)
  end

  def sent_email_messages_total_count_from_nylas
    return @total_sent_count if @total_sent_count.present?

    from = email
    to   = user.nylas_connected_email_account
    @total_sent_count = nylas_message_object.total_count(from: from, to: to)
  end

  def received_email_messages_total_count_from_nylas_in_past_year
    return @past_year_received_count if @past_year_received_count.present?

    from = user.nylas_connected_email_account
    to   = email
    @past_year_received_count = nylas_message_object.past_year_count(from: from, to: to)
  end

  def sent_email_messages_total_count_from_nylas_in_past_year
    return @past_year_sent_count if @past_year_sent_count.present?

    from = email
    to   = user.nylas_connected_email_account
    @past_year_sent_count = nylas_message_object.past_year_count(from: from, to: to)
  end

  def last_received_email_sent_at_from_nylas
    return @last_sent_at if @last_sent_at.present?

    from          = user.nylas_connected_email_account
    to            = email
    @last_sent_at = nylas_message_object.last_email_sent_at(from: from, to: to)

    return nil if @last_sent_at.nil?

    @last_sent_at = Time.zone.at(@last_sent_at)
  end

  def overall_last_contacted_at_from_nylas
    [last_received_email_sent_at_from_nylas, last_contacted_date].compact.max
  end

  def email_blank?
    email_addresses.collect(&:email).all?(&:blank?)
  end

  def phone_blank?
    phone_numbers.collect(&:number).all?(&:blank?)
  end

  def set_salutations
    format_envelope_salutation
    format_letter_salutation
  end

  def format_envelope_salutation
    strip_salutation_related_attributes
    self.envelope_salutation = Contact::SalutationService.new(self).envelope
  end

  def format_letter_salutation
    strip_salutation_related_attributes
    self.letter_salutation = Contact::SalutationService.new(self).letter
  end

  def strip_salutation_related_attributes
    [:spouse_first_name, :spouse_last_name, :first_name, :last_name].map do |attr|
      new_value = public_send(attr).try(:strip)
      self.public_send("#{attr}=", new_value)
    end
  end

  def work_info
    [title, company].reject(&:blank?).join(", ")
  end

  def populate_first_name_and_last_name_from_name
    if name.present? && first_name.blank? && last_name.blank?
      fname, *lname = name.split
      self.first_name = fname
      self.last_name = lname.join(" ")
    end
  end

  def self.per_page
    PER_PAGE
  end

  private

  def nylas_message_object
    @nylas_msg_object ||= NylasApi::Message.new(token: user.nylas_token)
  end

  def require_base_validations?
    require_base_validations.to_s == "true"
  end

  def require_basic_validations?
    require_basic_validations.to_s == "true"
  end

  def valid_base_validations?
    first_name.blank? && last_name.blank?
  end

  def valid_basic_validations?
    valid_base_validations? && email_blank? && phone_blank?
  end

  def base_validations
    if valid_base_validations?
      errors.add(:first_name, "Please enter a first name")
      errors.add(:last_name, "...or a last name")
    end
  end

  def basic_validations
    if valid_basic_validations?
      errors.add(:base, "Enter at least first name, last name, email or phone number")
    end
  end

  def required_salutations_to_set?
    self.required_salutations_to_set.to_s == "true"
  end

  def reloading_needed?
    # NOTE: This is currently handling all nested attributes. We need this
    # logic only for nested email addresses and phone numbers attributes and
    # that's why we need to better checks here for email addresses and phone
    # numbers and not for all.
    # Refer: #2255 (Github)

    send(:nested_records_changed_for_autosave?)
  end

  def set_force_reload
    self.force_reload = true
  end

  def force_reload_needed?
    self.force_reload
  end

  def force_reload!
    self.reload
  end

  def handle_subscription_token
    if saved_change_to_attribute?("unsubscribed")
      if saved_change_to_attribute?("unsubscribed", from: false, to: true)
        clear_attribute_changes(["unsubscribed"])
        self.subscription_token = nil
        self.save!
      else
        clear_attribute_changes(["unsubscribed"])
        regenerate_subscription_token
      end
    end
  end

  def handle_user_contact_groups
    groups = contact_groups_from(user)

    return if groups.blank?

    user_all_contact_groups = user.all_contact_groups.map(&:downcase)

    new_groups = groups.reject { |group| user_all_contact_groups.include? group.downcase }

    return if new_groups.blank?

    user_contact_groups_list = if user.contact_groups_list.nil?
                                 user.build_contact_groups_list
                               else
                                 user.contact_groups_list
                               end

    user_contact_groups_list.list += new_groups
    user_contact_groups_list.save!
  end

  def address_rejectable?(attr)
    attr[:id].blank? && attr[:street].blank? && attr[:city].blank? &&
      attr[:state].blank? && attr[:zip].blank?
  end

  def email_address_rejectable?(attr)
    attr[:id].blank? && attr[:email].blank?
  end

  def phone_rejectable?(attr)
    attr[:id].blank? && attr[:number].blank?
  end

  def important_date_rejectable?(attr)
    attr[:name].blank? && attr[:date_at].blank?
  end

end
