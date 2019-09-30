module IndexPageHelper

  def show_accordion_section?
    if request_from_mobile_app? || browser.device.mobile? || browser.device.tablet?
      ""
    else
      "active"
    end
  end

end
