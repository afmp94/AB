class MarketData::LocationSelector

  attr_reader :contact, :report_date_at, :user

  def initialize(contact_id: nil, user_id: nil, month: nil, year: nil)
    @contact = Contact.find(contact_id) if contact_id.present?
    @user = User.find(user_id) if user_id.present?
    @report_date_at = MarketData::ReportDateSelector.new.select(month: month, year: year)
  end

  def select
    @location ||= if use_default_location?
                    Rails.logger.error "use default location"
                    select_user_location
                  else
                    Rails.logger.error "use contact location"
                    select_contact_location
                  end
  end

  def use_default_location?
    select_contact_location.nil?
  end

  private

  def select_contact_location
    @contact_location ||= if @contact.present? && contact_has_address?
                            Rails.logger.error "zip code: #{contact_address.zip}"
                            if (zip_code = contact_address.zip) && market_zip_valid?(zip_code)
                              get_market_zip(zip_code)
                            elsif (city = contact_address.city) && market_city_valid?(city)
                              get_market_city(city)
                            elsif market_county_valid_and_has_data?(contact_address)
                              get_market_city(contact_address.city).market_county
                            end
                          end
  end

  def select_user_location
    if @user.present?
      if user.zip.present? && market_zip_valid?(user.zip)
        get_market_zip(user.zip)
      elsif user.city.present? && market_city_valid?(user.city)
        get_market_city(user.city)
      end
    end
  end

  def contact_has_address?
    contact_address.present?
  end

  def contact_address
    contact.primary_address
  end

  def get_market_zip(name)
    MarketZip.find_by(name: name)
  end

  def market_zip_exists?(name)
    get_market_zip(name).present?
  end

  def market_zip_valid?(name)
    market_zip_exists?(name) && location_has_data?(get_market_zip(name))
  end

  def get_market_city(name)
    MarketCity.find_by(name: name)
  end

  def market_city_exists?(name)
    get_market_city(name).present?
  end

  def market_city_valid?(name)
    market_city_exists?(name) && location_has_data?(get_market_city(name))
  end

  def market_county_valid_and_has_data?(contact_address)
    (city = contact_address.city) &&
      market_city_exists?(city) &&
      location_has_data?(get_market_city(city).market_county)
  end

  def location_has_data?(location)
    report = MarketReport.where(location: location, report_date_at: @report_date_at).first
    report.present? && report.number_of_listings > 5
  end

end
