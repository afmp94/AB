require "capybara/rails"
require "selenium-webdriver"

class MarketData::BaseScraper

  def find_and_click(css)
    find_css(css).click
    sub_log("Clicked on #{css}")
  end

  def find_and_clear(css)
    find_css(css).native.clear
    sub_log("Cleared #{css}")
  rescue
    false
  end

  def find_css(css)
    browser.find(css)
  end

  def css_not_displayed?(css)
    find_css(css).present? && !find_css(css).disabled?
    false
  rescue
    true
  end

  def clear_and_enter_in_textbox(css:, entry:)
    sub_log "entering #{entry} into #{css}"
    browser.fill_in(css, with: entry)
  end

  def clear_and_enter_in_multiselect(input_css:, list_css:, entry:)
    find_and_clear(input_css)
    select_from_dropdown(select_css: list_css, entry: entry)
  end

  def select_from_dropdown(select_css:, entry:)
    sub_log "Changing dropdown #{select_css} to #{entry}..."
    browser.select(entry, from: select_css)
  rescue
    sub_log "Could not select #{entry}. Item not in list."
    false
  end

  def accept_security_alert
    if alert_present?
      alert = driver.switch_to.alert
      alert.accept
    end
  end

  def alert_present?
    driver.switch_to.alert
    true
  rescue
    false
  end

  def windows
    driver.window_handles
  end

  def attach_to_window
    driver.switch_to.window(windows.first)
  end

  def switch_to(window_number)
    driver.switch_to.window(windows[window_number])
  end

  def key_to_string(key)
    key.to_s.humanize(capitalize: false)
  end

  def key_to_class(key)
    key.to_s.classify.constantize
  end

  def log(message)
    Rails.logger.info(message)
  end

  def sub_log(message)
    log("  *#{message}")
  end

  def title_log(message)
    log("\n#{'=' * message.length}\n#{message}\n#{'=' * message.length}\n")
  end

  def underline_log(message)
    log("#{message}\n#{'-' * message.length}")
  end

  def overline_log(message)
    log("\n#{'-' * message.length}\n#{message}")
  end

end
