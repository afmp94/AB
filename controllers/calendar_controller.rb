class CalendarController < ApplicationController

  def index
    render
  end

  def new_event
    @presenter = Calendar::NylasEventPresenter.new(nil, view_context)
  end

  def edit_event
    nylas_event = NylasApi::CalendarEvent.find(params[:id], current_user)
    @presenter  = Calendar::NylasEventPresenter.new(nylas_event, view_context)
  end

  def create_event
    event_params = params[:event]
    @calendar    = NylasApi::Calendar.new(current_user)

    if @calendar.create_event(event_params)
      flash[:notice] = "Event has been created successfully"

      redirect_to redirect_to_path
    else
      render
    end
  end

  def update_event
    event_params = params[:event]

    nylas_event = NylasApi::CalendarEvent.find(params[:id], current_user)
    @calendar   = NylasApi::Calendar.new(current_user)

    if @calendar.update_event(nylas_event, event_params)
      flash[:notice] = "Event has been updated successfully"
      redirect_to calendar_path
    else
      render
    end
  end

  private

  def redirect_to_path
    case params[:from_page]
    when "dashboard"
      dashboard_path
    else
      calendar_path
    end
  end

end
