require "csv"

class MarketData::CtmlsAgentScraper < MarketData::BaseCtmlsScraper

  attr_accessor :browser, :board
  attr_reader :driver

  def initialize(board: nil, driver: :selenium_chrome)
    @driver = driver

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

    Capybara.default_driver = @driver

    @browser = Capybara.current_session
    @board = board
  end

  def sign_in_to_matrix
    @browser.visit("https://idp.ctmls.safemls.net/idp/Authn/UserPassword")
    @browser.within("#loginform") do
      @browser.fill_in("j_username", with: "ogradyp")
      @browser.fill_in("password", with: "g0flyers")
      @browser.click_button("loginbtn")
    end
    @browser.find(".quick-links > .quick-link:first-child > a").click

    if @driver == :selenium_chrome
      @browser.switch_to_window(@browser.windows.last)
    end
  end

  def capture_all_agents
    start_time = Time.current

    csv_file_name = "ctmls_agents.csv"
    columns = agent_report_columns

    CSV.open(csv_file_name, "a+") do |csv_file|
      csv_file << columns.values
    end

    ctmls_boards.each do |board|
      overline_log("Getting #{board}...")
      open_agent_report(board: board)
      capture_all_report_data(
        columns: columns,
        csv_file_name: csv_file_name
      )
    end

    overline_log("Agent data capture complete.")
    log("Total time: #{total_time(start_time)}")
  end

  def open_agent_report(board: @board)
    @browser.visit("http://smartmls.mlsmatrix.com/Matrix/Search/Agent")
    @browser.select(board, from: "Fm4_Ctrl644_LB")
    @browser.find("#m_ucSearchButtons_m_lbSearch").click
  end

  def open_single_agent_property_report(mls_id:)
    @browser.visit("http://smartmls.mlsmatrix.com/Matrix/Search/CrossProperty/CrossPropertySearch")
    @browser.fill_in("Fm1_Ctrl160_TextBox", with: mls_id)
    @browser.find(:css, "[value='101']").set(true) # Active
    @browser.find(:css, "[value='1187']").set(true) # Show
    @browser.find(:css, "[value='1184']").set(true) # Deposit
    @browser.find(:css, "[value='1183']").set(true) # Closed
    @browser.fill_in("FmFm1_Ctrl112_1183_Ctrl112_TB", with: "01/01/2013-08/25/2017")
    @browser.find("#m_ucSearchButtons_m_lbSearch").click
  end

  def capture_all_report_data(columns:, csv_file_name:)
    start_time = Time.current

    page = 1

    CSV.open(csv_file_name, "a+") do |csv_file|
      while page <= total_pages
        @browser.find(".resultsMenu.tabbedMenu").has_content?("[#{page}]")
        break if page != current_page
        sub_log "page #{page}"
        capture_data_on_current_page(csv_file: csv_file, columns: columns)

        click_next_page_link
        page += 1
      end
    end

    log("Summary:")
    sub_log("Records: #{total_agents}")
    sub_log("Pages: #{total_pages}")
    sub_log("Time: #{total_time(start_time)}")
  end

  def capture_data_on_current_page(csv_file:, columns:)
    page = Nokogiri::HTML.parse(@browser.html)

    page.css("table.displayGrid tbody > tr").each_with_index do |row, index|
      log("\nPage row: #{index}")
      cells = row.css("td")

      csv_row = []
      columns.each do |key, _value|
        log("#{_value} => #{cells[key].text}")
        csv_row << cells[key].text
      end
      csv_file << csv_row
    end
  end

  def next_page_link
    @browser.within("#m_lblPagingSummary") do
      if @browser.has_link?("Next")
        @browser.find_link("Next")
      end
    end
  end

  def has_next_page_link?
    next_page_link.present? && !next_page_link.disabled?
  end

  def click_next_page_link
    if has_next_page_link?
      next_page_link.click
    end
  end

  def total_agents
    if report_has_data?
      @browser.find("span#m_lblPagingSummary > b:nth-child(4)").text.to_i
    else
      0
    end
  end

  def total_pages
    (total_agents.to_f / 100.0).ceil
  end

  def current_page
    (@browser.find("span#m_lblPagingSummary > b:nth-child(2)").text.to_f / 100.0).ceil
  end

  def report_has_data?
    @browser.has_css?("span#m_lblPagingSummary")
  end

  def agent_report_columns
    {
      1 => :agent_id,
      2 => :last_name,
      3 => :first_name,
      4 => :phone,
      5 => :home_phone,
      6 => :other_phone,
      7 => :email,
      8 => :status,
      9 => :muc,
      10 => :user_type,
      11 => :license_number,
      12 => :office_id,
      13 => :office_name,
      14 => :office_address,
      15 => :nrds_member_id,
      16 => :matrix_modified_dt,
      17 => :board,
      18 => :comments,
      19 => :web_page_address
    }
  end

  def cross_property_report_columns
    {
      2 => :mls_number,
      3 => :status,
      4 => :close_date,
      5 => :days_on_market,
      6 => :property_type,
      7 => :address,
      8 => :address2,
      9 => :city,
      10 => :original_list_price,
      11 => :list_price,
      12 => :current_price,
      13 => :close_price,
      14 => :assessed_value,
      15 => :list_agent_mls_id,
      16 => :co_list_agent_mls_id,
      17 => :list_office_mls_id,
      18 => :selling_agent_mls_id,
      19 => :co_selling_agent_mls_id,
      20 => :selling_office_mls_id,
      21 => :buyer_agent_compensation_amount,
      22 => :buyer_agent_compensation_type,
      23 => :buyer_agent_compensation_additional_info,
      24 => :compensation_notes,
      25 => :acres,
      26 => :sq_ft,
      27 => :style,
      28 => :rooms,
      29 => :beds,
      30 => :baths,
      31 => :garages,
      32 => :built
    }
  end

  def ctmls_boards
    [
      "Bridgeport",
      "Darien",
      "Eastern CT",
      "Greater Fairfield",
      "Greater Hartford",
      "Greater New Milford",
      "Greater Waterbury",
      "Greenwich",
      "Litchfield County",
      "Mid-Fairfield County",
      "Mid-State",
      "New Canaan",
      "New Haven Middlesex",
      "Newtown",
      "Northern Fairfield County",
      "Ridgefield",
      "Stamford",
      "Valley",
      "Rhode Island",
      "Westchester Putnam",
      "RETS User",
      "Smart MLS",
    ]
  end

  def total_time(start_time)
    total_seconds = Time.current - start_time
    minutes = (total_seconds / 60).to_i
    seconds = (total_seconds % 60).round(2)

    if minutes.zero?
      "#{seconds} seconds"
    else
      "#{minutes} minutes #{seconds} seconds"
    end
  end

end
