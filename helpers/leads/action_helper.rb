module Leads::ActionHelper

  def display_action_glyphicon(lead)
    if most_recent_activity = lead.most_recent_activity
      if most_recent_activity == lead.most_recent_contact_activity
        case most_recent_activity.activity_type
        when "Call"
          content_tag(:i, "", class: "mdi-communication-phone")
        when "Note"
          content_tag(:i, "", class: "mdi-content-mail")
        when "Visit"
          content_tag(:i, "", class: "mdi-social-group")
        when "Meeting"
          content_tag(:i, "", class: "mdi-social-group")
        when "Lunch"
          content_tag(:i, "", class: "mdi-maps-restaurant-menu")
        end
      else
        content_tag(:i, "", class: "mdi-action-done")
      end
    end
  end

end
