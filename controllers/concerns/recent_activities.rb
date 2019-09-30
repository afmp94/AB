module RecentActivities

  private

  def all_activities(page)
    activities = PublicActivity::Activity.order("created_at desc").page(page).per(100)

    activities_url = recent_activities_path(activities_owner_id: nil,
                                            activities_owner_type: nil,
                                            activity_feed_page: activities.next_page)
    [activities, activities_url]
  end

  def team_activities(user, page)
    activities = PublicActivity::Activity.where(owner_id: user.team_member_ids).
                 order("created_at desc").page(page).per(15)

    activities_url = recent_activities_path(activities_owner_id: nil,
                                            activities_owner_type: "Team",
                                            activity_feed_page: activities.next_page)
    [activities, activities_url]
  end

  def contact_activities(contact, page)
    activities     = contact.recent_activities(page: page)
    activities_url = recent_activities_path(activities_owner_id: contact.id,
                                            activities_owner_type: contact.class.name,
                                            activity_feed_page: activities.next_page)
    [activities, activities_url]
  end

  def lead_activities(lead, page)
    activities     = lead.recent_activities(page: page)
    activities_url = recent_activities_path(activities_owner_id: lead.id,
                                            activities_owner_type: lead.class.name,
                                            activity_feed_page: activities.next_page)
    [activities, activities_url]
  end

end
