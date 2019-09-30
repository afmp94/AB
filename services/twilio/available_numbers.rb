class Twilio::AvailableNumbers < ApplicationService

  SUPPORTED_COUNTRIES = %w[US CA].freeze
  COUNT_LIMIT = 10

  include Twilio::TwilioSupport

  def initialize(area_code:)
    @area_code = area_code
  end

  def call
    numbers.first(COUNT_LIMIT)
  end

  private

  attr_reader :area_code

  def supported_countries
    SUPPORTED_COUNTRIES.map { |country| available_phone_numbers.get(country) }
  end

  def numbers
    supported_countries.
      map(&:local).
      map { |local| local.list(phone_requirements) }.
      flatten
  end

  def phone_requirements
    {
      area_code: area_code,
      mms: true,
      sms: true
    }
  end

end
