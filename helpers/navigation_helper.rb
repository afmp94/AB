module NavigationHelper

  def nav_link(text, path, options={})
    options[:class] = current_page?(path) ? "item active" : "item"
    options[:title] = text unless options.has_key?(:title)

    link_to(text, path, options)
  end

  def list_item_link(text, path, condition=false, _options={})
    class_name = (current_page?(path) || condition) ? "active" : ""

    _options[:class] = "#{_options[:class]} item #{class_name}"

    link_to(text, path, _options)
  end

  def controller?(*controller)
    controller.include?(params[:controller])
  end

  def action?(*action)
    action.include?(params[:action])
  end

  def in_leads?(lead=nil)
    controller?("leads") && lead_action?(lead)
  end

  def in_clients?(lead=nil)
    in_leads_or_child_controller? && !lead_action?(lead)
  end

  def in_settings?
    controller?("users") || controller?("profiles") ||
      controller?("user_settings/lead_settings") || controller?("registrations") ||
      controller?("user_settings/teams")
  end

  private

  def in_leads_or_child_controller?
    controller?("leads") || controller?("properties") || controller?("contracts")
  end

  def lead_action?(lead)
    action?("user_leads") || action?("new_lead_lead") || action?("create_new_lead") ||
      (action?("show") && lead && lead.status == 0)
  end

end
