class ActivitiesController < ApplicationController

  include RecentActivities

  def index
    @activities, @activities_url = all_activities(params[:activity_feed_page])
  end

  def recent
    id   = params[:activities_owner_id]
    page = params[:activity_feed_page]
    type = params[:activities_owner_type]

    @activities, @activities_url =  case type
                                    when "Lead"
                                      lead = Lead.find(id)
                                      lead_activities(lead, page)
                                    when "Contact"
                                      contact = Contact.find(id)
                                      contact_activities(contact, page)
                                    when "Team"
                                      team_activities(current_user, page)
                                    else
                                      all_activities(page)
                                    end
  end

end
