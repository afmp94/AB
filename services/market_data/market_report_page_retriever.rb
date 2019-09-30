class MarketData::MarketReportPageRetriever

  def initialize(zip_code, city)
    @mechanize = Mechanize.new
    @mechanize.user_agent_alias = "Mac Safari"
    @zip_code = zip_code
    @city = city.parameterize
  end

  def fetch
    if raw_page
      raw_page.parser
    else
      false
    end
  end

  private

  def trulia_url
    "http://www.trulia.com/real_estate/#{@zip_code}-#{@city}/"
  end

  def raw_page
    @mechanize.get(trulia_url)
  rescue Mechanize::ResponseCodeError => e
    Rails.logger.error "[MARKET_DATA] Error fetching page: #{e}"
    false
  end

end
