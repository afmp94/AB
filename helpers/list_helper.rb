module ListHelper

  def fixed_list_item(name, value=nil, &block)
    if block
      value = capture(&block)
    end

    render(
      partial: "shared/scaffold/fixed_list/item",
      locals: { name: name, value: value }
    )
  end

  def fixed_list_header(header, edit_link=nil, link_id=nil, _collapse_id=nil)
    render(
      partial: "shared/scaffold/fixed_list/header",
      locals: { header: header, edit_link: edit_link, link_id: link_id }
    )
  end

  def action_list_item(options={})
    # Required arguments: title, description, icon_class
    # Optional arguments: link, link_data_method,
    # link_attributes, icon_attribtues

    options[:link] = nil if options[:link].blank?
    options[:link_attributes] = nil if options[:link_attributes].blank?
    options[:icon_attributes] = nil if options[:icon_attributes].blank?

    options[:data_method] = if options[:link_data_method].present?
                              "data-method=#{options[:link_data_method]}"
                            end

    render(partial: "shared/action_list_item", locals: options)
  end

end
