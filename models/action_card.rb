# == Schema Information
#
# Table name: action_cards
#
#  action        :string
#  card_type     :string
#  created_at    :datetime         not null
#  description   :text
#  header        :string
#  icon          :string
#  icon_color    :string
#  id            :bigint(8)        not null, primary key
#  link          :string
#  name          :string
#  order         :integer
#  sub_card_type :string
#  updated_at    :datetime         not null
#

class ActionCard < ActiveRecord::Base

  include ActionCards::NewUserCards
  include ActionCards::Coaching::Branding
  include ActionCards::Coaching::RelationshipAndDatabase
  include ActionCards::Coaching::PersonalAndMassMarketing
  include ActionCards::Coaching::LeadResponseAndConversion
  include ActionCards::Coaching::ServiceManagement
  include ActionCards::Coaching::SelfAndBusinessManagement

  validates :order, presence: true, uniqueness: { scope: :card_type }
  validates :name, uniqueness: { scope: :card_type }, if: -> { name.present? }
  validates :header, :link, presence: true

  CARD_TYPES = {
    new_user: "new_user",
    coaching: "coaching"
  }

  SUB_CARD_TYPES = {
    branding_coaching: "branding_coaching",
    relation_and_database_coaching: "relation_and_database_coaching",
    personal_and_mass_marketing_coaching: "personal_and_mass_marketing_coaching",
    lead_response_and_conversion_coaching: "lead_response_and_conversion_coaching",
    service_management_coaching: "service_management_coaching",
    self_and_business_management_coaching: "self_and_business_management_coaching",
  }

  def self.create_new_user_cards!
    NEW_USER_CARDS.each do |card_values|
      self.create!(
        order: card_values[:order],
        header: card_values[:header],
        icon: card_values[:icon],
        description: card_values[:description],
        action: card_values[:action],
        link: card_values[:link],
        card_type: CARD_TYPES[:new_user]
      )
    end
  end

  def self.create_branding_coaching_cards!
    BRANDING_COACHING_CARDS.each do |card_values|
      self.create!(
        order: card_values[:order],
        name: card_values[:name],
        header: card_values[:header],
        icon: card_values[:icon],
        icon_color: card_values[:icon_color],
        description: card_values[:description],
        action: card_values[:action],
        link: card_values[:link],
        card_type: CARD_TYPES[:coaching],
        sub_card_type: SUB_CARD_TYPES[:branding_coaching]
      )
    end
  end

  def self.create_relation_and_database_coaching_cards!
    RD_COACHING_CARDS.each do |card_values|
      self.create!(
        order: card_values[:order],
        name: card_values[:name],
        header: card_values[:header],
        icon: card_values[:icon],
        icon_color: card_values[:icon_color],
        description: card_values[:description],
        action: card_values[:action],
        link: card_values[:link],
        card_type: CARD_TYPES[:coaching],
        sub_card_type: SUB_CARD_TYPES[:relation_and_database_coaching]
      )
    end
  end

  def self.create_personal_and_mass_marketing_coaching_cards!
    PERSONAL_AND_MASS_MARKETING_CARDS.each do |card_values|
      self.create!(
        order: card_values[:order],
        name: card_values[:name],
        header: card_values[:header],
        icon: card_values[:icon],
        icon_color: card_values[:icon_color],
        description: card_values[:description],
        action: card_values[:action],
        link: card_values[:link],
        card_type: CARD_TYPES[:coaching],
        sub_card_type: SUB_CARD_TYPES[:personal_and_mass_marketing_coaching]
      )
    end
  end

  def self.create_lead_response_and_conversion_coaching_cards!
    LEAD_RESPONSE_AND_CONVERSION_CARDS.each do |card_values|
      self.create!(
        order: card_values[:order],
        name: card_values[:name],
        header: card_values[:header],
        icon: card_values[:icon],
        icon_color: card_values[:icon_color],
        description: card_values[:description],
        action: card_values[:action],
        link: card_values[:link],
        card_type: CARD_TYPES[:coaching],
        sub_card_type: SUB_CARD_TYPES[:lead_response_and_conversion_coaching]
      )
    end
  end

  def self.create_service_management_coaching_cards!
    SERVICE_MANAGEMENT_CARDS.each do |card_values|
      self.create!(
        order: card_values[:order],
        name: card_values[:name],
        header: card_values[:header],
        icon: card_values[:icon],
        icon_color: card_values[:icon_color],
        description: card_values[:description],
        action: card_values[:action],
        link: card_values[:link],
        card_type: CARD_TYPES[:coaching],
        sub_card_type: SUB_CARD_TYPES[:service_management_coaching]
      )
    end
  end

  def self.create_self_and_business_management_coaching_cards!
    SELF_AND_BUSINESS_MANAGEMENT_CARDS.each do |card_values|
      self.create!(
        order: card_values[:order],
        name: card_values[:name],
        header: card_values[:header],
        icon: card_values[:icon],
        icon_color: card_values[:icon_color],
        description: card_values[:description],
        action: card_values[:action],
        link: card_values[:link],
        card_type: CARD_TYPES[:coaching],
        sub_card_type: SUB_CARD_TYPES[:self_and_business_management_coaching]
      )
    end
  end

  def displayable_for?(user)
    raise "This card should be used for new user" if card_type != CARD_TYPES[:new_user]

    case order
    when 1
      user.csv_files.count.zero?
    when 2
      user.profile_image.blank?
    when 3
      user.current_goal.nil?
    when 4
      !user.confirmed?
    when 5
      user.mobile_number.nil? && user.company.nil? && user.address.nil?
    when 6
      !user.has_enough_graded_contacts?
    when 7
      !user.has_nylas_token?
    when 8
      user.leads.client_current_pipeline_status.count < 2
    when 9
      user.tasks.count < 2
    when 10
      user.confirmed? && user.graded_contacts_count.nonzero? && user.email_campaigns.pending_and_sent.count.zero?
    when 11
      user.survey_results.count.zero?
    else
      false
    end
  end

  def mark_as_dismissed_for!(user_id)
    DismissedActionCard.create!(
      action_card_id: id,
      user_id: user_id,
      dismissed_at: Time.current,
      dismiss_type: "dismiss_now"
    )
  end

  def remind_later_for!(user_id, remind_after_days)
    DismissedActionCard.create!(
      action_card_id: id,
      user_id: user_id,
      dismiss_type: "remind_me_later",
      undismiss_at: Time.current + remind_after_days.to_i.days
    )
  end

end
