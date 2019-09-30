module CampaignMessageEventsHelper

  def order_activites_by_time(activities)
    activities.sort { |a, b| a.ts <=> b.ts }
  end

end
