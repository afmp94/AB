# == Schema Information
#
# Table name: email_campaigns
#
#  campaign_status         :integer          default("draft")
#  campaign_type           :string
#  color_scheme            :string
#  contact_ids_string      :string
#  contact_list            :integer          default([]), is an Array
#  contacts                :text
#  content                 :text
#  created_at              :datetime
#  custom_delivery_time    :boolean          default(FALSE)
#  custom_message          :text
#  delivered               :boolean
#  delivered_at            :datetime
#  display_custom_message  :boolean          default(FALSE)
#  email_status            :string
#  groups                  :text
#  id                      :integer          not null, primary key
#  image                   :string
#  last_clicked            :integer          default(0)
#  last_opened             :integer          default(0)
#  message_id              :string
#  message_id_list         :string           default([]), is an Array
#  message_ids_string      :string
#  name                    :string
#  recipient_selector_type :string
#  scheduled_delivery_at   :datetime
#  selected_grades         :integer          default([]), is an Array
#  selected_groups         :string           default([]), is an Array
#  send_generic_report     :boolean          default(TRUE)
#  subject                 :string
#  successful_deliveries   :integer          default(0)
#  title                   :string
#  total_clicks            :integer          default(0)
#  total_opens             :integer          default(0)
#  track_clicks            :boolean          default(TRUE)
#  track_opens             :boolean          default(TRUE)
#  unique_clicks           :integer          default(0)
#  unique_opens            :integer          default(0)
#  updated_at              :datetime
#  user_id                 :integer
#
# Indexes
#
#  index_email_campaigns_on_campaign_status  (campaign_status)
#  index_email_campaigns_on_email_status     (email_status)
#  index_email_campaigns_on_user_id          (user_id)
#

class EmailCampaign < ActiveRecord::Base

  CAMPAIGN_TYPES = { basic: "basic" }.freeze

  DELIVERY_TIMES = {
    optimize_time: "optimize_time",
    specific_time: "specific_time"
  }.freeze

  belongs_to :user
  has_one :campaign_image, as: :attachable, class_name: "Image", dependent: :destroy
  has_many :campaign_messages, dependent: :destroy
  accepts_nested_attributes_for :campaign_image

  scope :search_name, ->(search_term) { where("title ILIKE :search_term OR name ILIKE :search_term", search_term: "%#{search_term.downcase}%") }
  scope :pending_and_sent, -> { where(campaign_status: ["pending", "sent"]) }

  enum campaign_status: %i(draft scheduled pending sent)

  before_save :clean_selected_grades, :clean_selected_groups

  paginates_per(25)

  def campaign_image_url
    if campaign_image
      campaign_image.file.url
    else
      "https://placehold.it/200"
    end
  end

  def search_recipients(query)
    return [] if query.blank?

    @data     = []
    query     = "%#{query}%"
    condition = ["first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?",
                 query, query, query]

    recipients.where(condition).find_each do |recipient|
      formatted_name = "#{recipient.name} - #{recipient.email}"
      @data << { text: formatted_name, id: recipient.id }
    end

    { success: true, results: @data }
  end

  def recipients
    recipients_for(unsubscribed_status: false)
  end

  def unsubscribed_recipients
    recipients_for(unsubscribed_status: true)
  end

  def recipients_count
    recipients.count
  end

  def unsubscribed_recipients_count
    unsubscribed_recipients.count
  end

  def contact_location(contact)
    location_selector(contact).select
  end

  def location_name(contact)
    contact_location(contact).try(:name)
  end

  def location_source(contact)
    if location_selector(contact).use_default_location?
      :default
    else
      :contact
    end
  end

  def location_type(contact)
    contact_location(contact).class.name
  end

  def humanize_campaign_status
    case self.campaign_status
    when "draft"
      "Draft"
    when "pending"
      "In delivery"
    when "scheduled"
      "Scheduled for delivery"
    when "sent"
      "Sent"
    end
  end

  def opens_percentage
    EmailCampaign::ContactActivityReportService.new(self).opens_percentage
  end

  def clicks_percentage
    EmailCampaign::ContactActivityReportService.new(self).clicks_percentage
  end

  private

  def location_selector(contact)
    MarketData::LocationSelector.new(contact_id: contact.try(:id), user_id: self.user.id)
  end

  def clean_selected_grades
    selected_grades.reject!(&:blank?)
  end

  def clean_selected_groups
    selected_groups.reject!(&:blank?)
  end

  def recipients_for(unsubscribed_status:)
    contacts = user.contacts.active.where.not(email: nil)

    case recipient_selector_type
    when "grade"
      contacts.where(grade: selected_grades, unsubscribed: unsubscribed_status).order("name asc")
    when "group"
      contacts.where(unsubscribed: unsubscribed_status).tagged_with(selected_groups, any: true).order("name asc")
    else
      contacts.none
    end
  end

end
