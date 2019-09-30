module Superadmin::NylasDashboardHelper

  def table_row_color_class(state)
    case state
    when "active"
      "positive"
    when "inactive"
      "warning"
    when "failing"
      "negative"
    when "failed"
      "negative"
    end
  end

end
