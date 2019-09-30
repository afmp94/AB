module DropdownsHelper

  def drop_link(text, path, _condition=false, options={})
    options[:class] = current_page?(path) ? "item active" : "item"
    options[:title] = text unless options.has_key?(:title)
    options[:tabindex] = "-1" unless options.has_key?(:tabindex)

    link_to(text, path, options)
  end

end
