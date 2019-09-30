class MarketData::ReportDateSelector

  def select(month: nil, year: nil)
    if month && year
      Time.zone.parse("#{month}/#{year}")
    else
      most_current_report_date
    end
  end

  private

  def most_current_report_date
    if last_report = MarketReport.order("report_date_at desc").first
      last_report.report_date_at
    else
      (Time.current - 5.days).beginning_of_month - 1.month
    end
  end

end
