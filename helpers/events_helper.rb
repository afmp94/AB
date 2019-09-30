module EventsHelper

  def event_location_url(event)
    if event.location
      full_address = convert_event_location_to_full_address(event.location)

      GoogleApi::MapsApiService.new(full_address).google_image_url
    else
      ""
    end
  end

  def event_cal_date_attribute(event)
    if event_attribute(event.when, "start_time")
      Time.zone.at(event_attribute(event.when, "start_time")).strftime("%-d")
    elsif event_attribute(event.when, "start_date")
      Time.zone.parse(event_attribute(event.when, "start_date").to_s).strftime("%-d")
    elsif event_attribute(event.when, "date")
      Time.zone.parse(event_attribute(event.when, "date").to_s).strftime("%-d")
    elsif event_attribute(event.when, "time")
      Time.zone.at(event_attribute(event.when, "time")).strftime("%-d")
    end
  end

  def event_day_date_attribute(event)
    if event.when.try(:start_time)
      Time.zone.at(event.when.try(:start_time)).strftime("%b")
    elsif event.when.try(:start_date)
      Time.zone.parse(event.when.try(:start_date).to_s).strftime("%b")
    elsif event.when.try(:date)
      Time.zone.parse(event.when.try(:date).to_s).strftime("%b")
    elsif event.when.try(:time)
      Time.zone.at(event.when.try(:time)).strftime("%b")
    end
  end

  def formated_nylas_event_start_to_end_time(event)
    if event.when
      if event.when.try(:start_time) && event.when.try(:end_time)
        Time.zone.at(event.when.try(:start_time)).strftime("%l:%M") +
          "-" +
          Time.zone.at(event.when.try(:end_time)).strftime("%l:%M %p")
      elsif event.when.try(:start_time)
        Time.zone.at(event.when.try(:start_time)).strftime("%l:%M %p")
      elsif event.when.try(:date)
        event.when.try(:date)
      elsif event.when.try(:time)
        Time.zone.at(event.when.try(:time)).strftime("%l:%M %p")
      end
    end
  end

  def format_event_date_and_time(event)
    formatted_start_n_end_time = formated_nylas_event_start_to_end_time(event)
    unique_cal_date_label = event_cal_date_attribute(event)
    unique_day_date_label = event_day_date_attribute(event)

    if formatted_start_n_end_time.present?
      "#{formatted_start_n_end_time} | #{unique_cal_date_label} #{unique_day_date_label}"
    else
      "#{unique_cal_date_label} #{unique_day_date_label}"
    end
  end

  def convert_event_location_to_full_address(location)
    address_info = location.split(",")
    joiner = "+"

    address_info.select(&:present?).map do |info|
      info.gsub(" ", joiner)
    end.join(joiner)
  end

  def group_events(events)
    events.each.group_by do |event|
      next if [Date.current.day, (Time.current + 1.day).day].exclude? event_cal_date_attribute(event).to_i

      if event_cal_date_attribute(event) == Time.current.strftime("%-d")
        :today
      else
        :tomorrow
      end
    end
  end

  def event_attribute(event_when, attribute)
    if [Hash, ActiveSupport::HashWithIndifferentAccess].include?(event_when.class)
      event_when[attribute]
    else
      event_when.try(attribute.to_sym)
    end
  end

end
