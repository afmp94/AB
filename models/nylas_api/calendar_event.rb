class NylasApi::CalendarEvent

  require "net/http"
  require "uri"
  require "json"

  attr_reader :nylas_event, :errors, :full_day, :params

  DATESPAN = "datespan".freeze
  TIMESPAN = "timespan".freeze

  def initialize(user, params)
    @user     = user
    @params   = params
    @account  = NylasApi::Account.new(@user.nylas_token).retrieve

    raise(ArgumentError, "please provide required params data") if @params.blank?

    @full_day = @params[:full_day]

    @nylas_event = @account.events.new(
      calendar_id: user.nylas_calendar_setting_id,
      title: params[:title],
      when: { object: (@full_day == "1" ? DATESPAN : TIMESPAN) }
    )
    @nylas_event
  end

  def self.find(id, user)
    account = NylasApi::Account.new(user.nylas_token).retrieve
    account.events.find(nylas_event_id(id))
  end

  def create
    set_other_attributes

    if valid_nylas_event?
      Util.create_event(nylas_event)
      true
    else
      false
    end
  end

  def update(old_nylas_event)
    set_other_attributes

    if valid_nylas_event?
      nylas_event.id = old_nylas_event.id
      Util.update_event(nylas_event)
      true
    else
      false
    end
  end

  def self.nylas_event_id(id)
    id.split("_")[0]
  end

  private

  def set_other_attributes
    if (nylas_event_object == TIMESPAN)
      if params[:start_time].present?
        self.nylas_event_start_time = Time.zone.parse(params[:start_time]).to_i
      end

      if params[:end_time].present?
        self.nylas_event_end_time = Time.zone.parse(params[:end_time]).to_i
      end
    end

    if (nylas_event_object == DATESPAN)
      if params[:start_date].present?
        self.nylas_event_start_date = Date.parse(params[:start_date]).to_s
      end

      if params[:end_date].present?
        self.nylas_event_end_date = Date.parse(params[:end_date]).to_s
      end
    end

    if params[:participants].present?
      participants = []

      params[:participants].split(",").each do |participant_email|
        participants << {
          email: participant_email&.strip
        }
      end

      @nylas_event.participants = participants
    end

    nylas_event.location    = params[:location] if params[:location].present?
    nylas_event.description = params[:description] if params[:description].present?
  end

  def valid_nylas_event?
    valid   = false
    @errors = []

    @errors << "Title can't be blank" if nylas_event.title.blank?

    if nylas_event_object == TIMESPAN
      if nylas_event_start_time.blank? || nylas_event_end_time.blank?
        @errors << "Start time and End time can't be blank"
      elsif Time.zone.at(nylas_event_start_time) > Time.zone.at(nylas_event_end_time)
        @errors << "Start date and time must be prior to End Date and Time"
      end
    elsif nylas_event_object == DATESPAN
      if nylas_event_start_date.blank? || nylas_event_end_date.blank?
        @errors << "Start date and End date can't be blank"
      elsif nylas_event_start_date > nylas_event_end_date
        @errors << "Start date and time must be prior to End Date and Time"
      end
    else
      @errors << "Start and End date/time must be provided"
    end

    if @errors.blank?
      after_validation_hooks
      valid = true
    end

    valid
  end

  def after_validation_hooks
    if full_day
      if nylas_event_start_date.present? && nylas_event_end_date.present? &&
          nylas_event_start_date == nylas_event_end_date

        set_nylas_event_object_as_date_object
      end
    end
  end

  def set_nylas_event_object_as_date_object
    self.nylas_event_object = "date"
    nylas_event.when.date = nylas_event_start_date.to_s
    nylas_event.when.start_date = nil
    nylas_event.when.end_date = nil
  end

  def nylas_event_object
    nylas_event.when.object
  end

  def nylas_event_object=(data)
    if nylas_event.when.class == Hash
      nylas_event.when[:object] = data
    else
      nylas_event.when.object = data
    end
  end

  def nylas_event_start_date
    nylas_event.when.start_date
  end

  def nylas_event_start_date=(data)
    nylas_event.when.start_date = data
  end

  def nylas_event_end_date
    nylas_event.when.end_date
  end

  def nylas_event_end_date=(data)
    nylas_event.when.end_date = data
  end

  def nylas_event_start_time
    if nylas_event.when.class == Hash
      nylas_event.when[:start_time]
    else
      nylas_event.when.start_time
    end
  end

  def nylas_event_start_time=(data)
    if nylas_event.when.class == Hash
      nylas_event.when[:start_time] = data
    else
      nylas_event.when.start_time = data
    end
  end

  def nylas_event_end_time
    if nylas_event.when.class == Hash
      nylas_event.when[:end_time]
    else
      nylas_event.when.end_time
    end
  end

  def nylas_event_end_time=(data)
    if nylas_event.when.class == Hash
      nylas_event.when[:end_time] = data
    else
      nylas_event.when.end_time = data
    end
  end

end
