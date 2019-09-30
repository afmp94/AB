class TeamsViewService

  attr_reader :team

  def initialize(team)
    @team  = team
  end

  def teammate_status teammate
    case teammate.status
    when "invited"
      "Requested Teammate"
    when "teammate"
      "Teammate"
    when "rejected"
      "Rejected Invite"
    else
      "Invalid"
    end
  end

  def remove_teammate_label teammate
    case teammate.status
    when "invited"
      "Cancel Request"
    when "teammate"
      "Remove"
    else
      "Invalid"
    end
  end

end
