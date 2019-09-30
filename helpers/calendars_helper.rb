module CalendarsHelper

  def determine_user_calendar(calendars, user)
    user_calendar = nil

    calendars.each do |calendar|
      if calendar.id == user.nylas_calendar_setting_id
        user_calendar = calendar
      end
    end

    user_calendar
  end

  def time_to_next_quarter_hour(time)
    # https://gist.github.com/citrus/1107932
    array    = time.to_a
    quarter  = ((array[1] % 60) / 15.0).ceil
    array[1] = (quarter * 15) % 60
    Time.local(*array) + (quarter == 4 ? 3600 : 0)
  end

end
