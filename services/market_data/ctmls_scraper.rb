class MarketData::CtmlsScraper < MarketData::BaseCtmlsScraper

  attr_accessor :browser, :driver, :start_month, :start_year, :end_month, :end_year

  def initialize(
    start_month: "January",
    start_year: "2016",
    end_month: nil,
    end_year: nil
  )
    @start_month = start_month
    @start_year = start_year
    @end_month = end_month.nil? ? start_month : end_month
    @end_year = end_year.nil? ? start_year : end_year

    Capybara.register_driver(:headless_chrome) do |app|
      browser_options = ::Selenium::WebDriver::Chrome::Options.new
      browser_options.args << "--headless"
      browser_options.args << "--disable-gpu"
      browser_options.args << "--window-size=1200,800"

      Capybara::Selenium::Driver.new(
        app,
        browser: :chrome,
        options: browser_options
      )
    end

    @driver = :headless_chrome

    Capybara.default_driver = @driver

    @browser = Capybara.current_session

    go_to_matrix_dashboard
    click_on_stats_tab
  end

  def fetch_one_report(location_type:, report:)
    click_on_stats_tab
    setup_report_fields(report)

    run_reports(location_type: location_type, report: report)
  end

  def fetch_multiple_reports(location_type:, reports: [])
    click_on_stats_tab
    setup_report_fields(reports.first)

    reports.each do |report|
      title_log("Fetching #{MarketReport::REPORT_TYPES[report][:column]} report for #{key_to_string(location_type)}")

      select_report_type(report)
      run_reports(location_type: location_type, report: report)
    end
  end

  def setup_report_fields(report)
    browser.find("#m_btnCustomizeTab").click
    enter_timeframe
    select_report_type(report)
    enter_search_attributes
  end

  def run_reports(location_type:, report:)
    starting_time = Time.current
    location_klass = key_to_class(location_type)
    location_string = key_to_string(location_type)

    total_locations = location_klass.count
    fetched_locations = 0
    locations_not_found = []
    locations_without_data = []

    location_klass.all.each do |location|
      location_name = location.name
      overline_log "Getting #{location_string}: #{location_name}...\n"
      input_method = "enter_#{location_type}"

      if send(input_method, location_name) == false
        locations_not_found << location_name
      else
        click_generate_report_button(location_type: location_type)
        data = get_report_data
      end

      save_market_report_data(data: data, location: location, report: report)

      locations_without_data << location_name if data.nil?
      fetched_locations += 1
      underline_log(
        "\n#{fetched_locations}/#{total_locations} complete | #{location_name}"\
        " | #{MarketReport::REPORT_TYPES[report][:column]}: #{data}"
      )
    end

    elapsed_time = (Time.current - starting_time).round
    title_log(
      "#{fetched_locations} #{location_string.pluralize} | "\
      "#{MarketReport::REPORT_TYPES[report][:column]} | "\
      "#{(elapsed_time / 60) % 60} minutes #{elapsed_time % 60} seconds"
    )

    if !locations_without_data.empty?
      overline_log("No data for #{locations_without_data.length} locations")
      locations_without_data.each { |location| sub_log(location) }
    end

    if !locations_not_found.empty?
      overline_log("Could not find #{locations_without_data.length} locations")
      locations_not_found.each { |location| sub_log(location) }
    end
  end

  def enter_timeframe
    select_from_dropdown(
      select_css: "m_ucStatsCustomize$m_drPeriod$m_ddlTimePeriod",
      entry: "Custom"
    )
    input_start_date
    input_end_date
  end

  def input_start_date
    select_from_dropdown(
      select_css: "m_ucStatsCustomize$m_drPeriod$m_ddlStartMonth",
      entry: @start_month
    )
    select_from_dropdown(
      select_css: "m_ucStatsCustomize$m_drPeriod$m_ddlStartYear",
      entry: @start_year.to_s
    )
  end

  def input_end_date
    select_from_dropdown(
      select_css: "m_ucStatsCustomize$m_drPeriod$m_ddlEndYear",
      entry: @end_year.to_s
    )
    select_from_dropdown(
      select_css: "m_ucStatsCustomize$m_drPeriod$m_ddlEndMonth",
      entry: @end_month
    )
  end

  def select_report_type(report)
    select_from_dropdown(
      select_css: "m_ucStatsCustomize$m_mcPrimaryMeasure$m_ddlMeasures",
      entry: MarketReport::REPORT_TYPES[report][:field]
    )
  end

  def enter_search_attributes
    select_from_dropdown(
      select_css: "m_ucStatsCustomize$m_dcDimensions$m_ddlPrimaryDimensions",
      entry: "Month"
    )
    browser.find(:css, "[value='151']").set(true)
  end

  def enter_market_zip(zip_code)
    click_search_criteria_button
    clear_and_enter_in_textbox(css: "Fm8_Ctrl618_TextBox", entry: zip_code)
  end

  def enter_market_city(city)
    click_search_criteria_button
    find_and_clear("#Fm8_Ctrl121_LB_TB")
    enter_town = clear_and_enter_in_multiselect(
      input_css: "#Fm8_Ctrl120_LB_TB",
      list_css: "Fm8_Ctrl120_LB",
      entry: format_direction(city)
    )
    if enter_town == false
      clear_and_enter_in_multiselect(
        input_css: "#Fm8_Ctrl121_LB_TB",
        list_css: "Fm8_Ctrl121_LB",
        entry: MarketCity::AREAS[format_direction(city)].to_s
      )
    else
      true
    end
  end

  def enter_market_county(county)
    click_search_criteria_button
    clear_and_enter_in_multiselect(
      input_css: "#Fm8_Ctrl119_LB_TB",
      list_css: "Fm8_Ctrl119_LB",
      entry: county
    )
  end

  def get_report_data
    data_tab = find_css("#m_btnData")

    if data_tab.disabled?
      sub_log("No data")
      nil
    else
      data_tab.click
      data = find_css(".statsDataRowOdd > td + td").text
      sub_log("Data: #{data}")
      data.delete(",$%")
    end
  end

  def save_market_report_data(data:, location:, report:)
    report_date = Time.zone.parse("#{end_month} #{end_year}")

    market_report = MarketReport.find_or_create_by(report_date_at: report_date, location: location)
    market_report.update!(MarketReport::REPORT_TYPES[report][:column] => data.nil? ? 0 : data)
  end

end
