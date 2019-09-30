module SurveyResultsHelper

  def set_icon_class(state)
    if state
      "check green"
    else
      "remove red"
    end
  end

  def progress_bar_class(width)
    if width >= 80
      "green"
    elsif width >= 40 && width < 80
      "yellow"
    else
      "red"
    end
  end

  def main_gauge_percentage(services)
    count = services.size
    total_percentage = 0
    services.each do |service|
      total_percentage += service.public_send(:total_score_in_percentage)
    end

    (total_percentage / count).round
  end

end
