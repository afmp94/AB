class NylasAccountsController < ApplicationController

  def messages
    @contact  = Contact.find(params[:contact_id])
    @messages = @contact.fetch_email_messages(current_user.nylas_token)
    render layout: false
  end

  def calendar
    if calendar = NylasApi::Calendar.new(current_user)
      @events = []

      if params[:period] == "recent"
        begin
          @events = calendar.recent_events
        rescue Nylas::AccessDenied => _
          user_name = current_user.name
          Rails.logger.error "Nylas account cancelled or trial expired for #{user_name}"
        end
      else
        begin
          @events = calendar.events_for(params[:start], params[:end])
          if current_user.super_admin?
            logger.info "*" * 100
            logger.info "Total events count for the calendar: #{@events.count}"
            logger.info @events.inspect
          end
        rescue Nylas::AccessDenied => _
          @events = []
          user_name = current_user.name
          Rails.logger.error "Nylas account cancelled or trial expired for #{user_name}"
        end
      end

      respond_to do |format|
        format.html { render layout: false }
        format.json { render json: calendar.events_to_json_format(@events) }
      end
    end
  end

end
