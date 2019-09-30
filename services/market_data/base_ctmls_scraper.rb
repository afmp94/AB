class MarketData::BaseCtmlsScraper < MarketData::BaseScraper

  def go_to_matrix_dashboard
    sign_in_to_ctmls
    navigate_to_matrix
  end

  def click_on_stats_tab
    sub_log("Opening stats tab...")
    browser.visit("http://smartmls.mlsmatrix.com/Matrix/Stats")
  end

  def navigate_to_agent_search_tab
    driver.navigate.to "http://smartmls.mlsmatrix.com/Matrix/Search/Agent"
    accept_security_alert
  end

  def click_generate_report_button(location_type:)
    sub_log "Wait for generate button to stop being disabled"
    browser.find("#m_tdGenerate:not(.disabled)")
    find_and_click("#m_btnGenerate")
  end

  def click_search_criteria_button
    find_and_click("#m_btnCriteria")
  rescue Exception => e
    sub_log "Could not find and click search button. Rescuing... #{e}"
  end

  def format_direction(string)
    string.gsub(/(North|South|East|West)\s/, directional_words)
  end

  private

  def sign_in_to_ctmls
    sub_log("Opening CTMLS sign in page...")
    browser.visit("https://idp.ctmls.safemls.net/idp/Authn/UserPassword")
    browser.within("#loginform") do
      browser.fill_in("j_username", with: "ogradyp")
      browser.fill_in("password", with: "g0flyers")
      browser.click_button("loginbtn")
      sub_log("Signing in to CTMLS...")
    end
  end

  def navigate_to_matrix
    sub_log("Opening Matrix...")
    browser.find(".quick-links > .quick-link:first-child > a").click

    if driver == :selenium_chrome
      browser.switch_to_window(browser.windows.last)
    end
  end

  def directional_words
    {
      "North " => "N ",
      "South " => "S ",
      "East " => "E ",
      "West " => "W ",
    }
  end

end
