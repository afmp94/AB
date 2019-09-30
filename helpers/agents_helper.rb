module AgentsHelper

  def label_color(status)
    case status
    when "invited"
      "yellow"
    when "active"
      "green"
    when "inactive"
      "red"
    end
  end

end
