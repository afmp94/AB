# == Schema Information
#
# Table name: addresses
#
#  address      :string
#  address_type :string
#  city         :string
#  county       :string
#  created_at   :datetime
#  data         :hstore
#  id           :integer          not null, primary key
#  owner_id     :integer
#  owner_type   :string
#  state        :string
#  street       :string
#  updated_at   :datetime
#  zip          :string
#
# Indexes
#
#  index_addresses_on_city                     (city)
#  index_addresses_on_owner_type_and_owner_id  (owner_type,owner_id)
#

class Address < ActiveRecord::Base

  audited
  TYPES = {
    home:  "Home",
    business: "Business",
    investment: "Investment",
    pre_owned: "Pre-owned",
    other: "Other"
  }.freeze

  belongs_to :owner, polymorphic: true

  attr_accessor :require_basic_address_validations

  validate :basic_address_validations, if: :require_basic_address_validations?
  validates_associated :owner

  def city_state_zip
    if city.blank? || state.blank?
      "#{city} #{state} #{zip}"
    else
      "#{city}, #{state} #{zip}"
    end
  end

  def one_line
    "#{street}, #{city}"
  end

  def full_address
    [street, city, state, zip].map(&:presence).compact.join(" ")
  end

  def require_basic_address_validations?
    require_basic_address_validations.to_s == "true"
  end

  def basic_address_validations
    if street.blank? && city.blank? && state.blank? && zip.blank?
      errors.add(:base, "Enter at least address, city, state or zip code")
    end
  end

  def primary?
    address_type == TYPES[:home]
  end

end
