class NylasApi::Calendar

  attr_reader :account, :user, :calendar_event_errors

  def initialize(user)
    @user    = user
    @account = NylasApi::Account.new(@user.nylas_token).retrieve
  end

  def create_event(event_params)
    calendar_event = NylasApi::CalendarEvent.new(user, event_params)
    if calendar_event.create
      true
    else
      @calendar_event_errors = calendar_event.errors
      false
    end
  end

  def update_event(nylas_event, event_params)
    calendar_event = NylasApi::CalendarEvent.new(user, event_params)
    if calendar_event.update(nylas_event)
      true
    else
      @calendar_event_errors = calendar_event.errors
      false
    end
  end

  def all
    account&.calendars
  end

  def todays_events
    recent_events.select do |event|
      Date.current.day == event_day(event).to_i
    end
  end

  def recent_events
    nylas_response = []
    if account && user.nylas_calendar_setting_id
      nylas_response = search_recent_events(account)
    end
    nylas_response
  end

  def events_for(start_date, end_date)
    nylas_response = []

    start_date = Time.zone.parse(start_date)
    end_date   = Time.zone.parse(end_date)

    if account && user.nylas_calendar_setting_id
      nylas_response = account.events.where(
        starts_after: start_date.to_i,
        ends_before: end_date.to_i,
        calendar_id: user.nylas_calendar_setting_id,
        expand_recurring: true,
        limit: 200
      )
    end

    nylas_response
  end

  def events_to_json_format(events)
    events_in_json = []

    events.each do |event|
      json_response = {
        id: event.id,
        title: event.title&.truncate(23),
        allDay: false,
        editable: (event.read_only != true),
        end: nil
      }

      case event.when.object
      when "time"
        # The 'tim'e subobject corresponds a single moment in time,
        # which has no duration. Reminders or alarms would be represented
        # as time subobjects.
        json_response[:start] = event.when.try(:time).try(:to_time).try(:iso8601)
      when "date"
        # A specific date for an event, without a clock-based starting or
        # end time. Your birthday and holidays would be represented as
        # date subobjects.

        json_response[:start]  = event.when.try(:date).try(:to_time).try(:iso8601)
        json_response[:allDay] = true
      when "timespan"
        json_response[:start] = Time.zone.at(event.when.start_time).iso8601
        json_response[:end]   = Time.zone.at(event.when.end_time).iso8601
      when "datespan"
        # A span of entire days without specific times.
        # A business quarter or academic semester would be represented as
        # datespan subobjects.

        json_response[:start]  = event.when.start_date.to_time.iso8601
        json_response[:end]    = event.when.end_date.to_time.iso8601

        # NOTE: This is a little hack to display multiple days with full day event
        # and 'allDay' option should be false.
        json_response[:end] = json_response[:end].gsub("00:00:00", "23:59:00")
        json_response[:allDay] = false
      end

      events_in_json << json_response
    end

    if user.super_admin?
      Rails.logger.info "#" * 100
      Rails.logger.info "Total events count for after converting into JSON: #{events_in_json.count}"
      Rails.logger.info events_in_json.inspect
    end

    events_in_json
  end

  private

  def get_events_for(period)
    nylas_response = []

    if account && user.nylas_calendar_setting_id
      range_starts = 0
      starts_after = Time.current.beginning_of_day

      case period
      when :recent
        range_ends  = 9;
        ends_before = (starts_after + 1.day).end_of_day
      when :year
        range_ends  = 99;
        ends_before = starts_after + 1.year
      end

      nylas_response = account.events.where(
        starts_after: starts_after.to_i,
        ends_before: ends_before.to_i,
        calendar_id: user.nylas_calendar_setting_id,
        expand_recurring: true
      ).offset(range_starts).limit(range_ends)

    end

    nylas_response
  end

  def valid_event?(new_event)
    @calendar_event_errors = []

    if new_event.title.blank?
      @calendar_event_errors << "Title can't be blank"
    end

    if new_event.when.object == "timespan"
      if new_event.when.start_time.blank? || new_event.when.end_time.blank?
        @calendar_event_errors << "Start time and End time can't be blank"
      elsif Time.zone.at(new_event.when.start_time) > Time.zone.at(new_event.when.end_time)
        @calendar_event_errors << "Start time should be in past comparing to End time"
      end
    elsif new_event.when.object == "datespan"
      if new_event.when.start_date.blank? || new_event.when.end_date.blank?
        @calendar_event_errors << "Start date and End date can't be blank"
      elsif new_event.when.start_date > new_event.when.end_date
        @calendar_event_errors << "Start date should be in past comparing to End date"
      end
    else
      @calendar_event_errors << "Start and End date/time must be provided"
    end

    @calendar_event_errors.blank?
  end

  def event_day(event)
    start = if event.when.start_time
              Time.zone.at(event.when.start_time)
            elsif event.when.start_date
              Time.zone.parse(event.when.start_date.to_s)
            elsif event.when.date
              Time.zone.parse(event.when.date.to_s)
            elsif event.when.time
              Time.zone.at(event.when.time)
            end

    start.strftime("%-d")
  end

  def search_recent_events(account)
    range_starts = 0
    range_ends   = 9
    starts_after = Time.zone.parse((Date.current - 1.day).to_s)
    ends_before = Time.zone.parse((Date.current + 2.days).to_s)

    account.events.where(
      starts_after: starts_after.to_i,
      ends_before: ends_before.to_i,
      calendar_id: user.nylas_calendar_setting_id,
      expand_recurring: true,
      offset: range_starts,
      limit: range_ends
    )
  end

end
