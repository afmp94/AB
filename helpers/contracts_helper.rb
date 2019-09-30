module ContractsHelper

  def set_redirect_or_render_page(page, for_page)
    page.presence || redirect_or_render_page_param(for_page)
  end

  private

  def redirect_or_render_page_param(for_page)
    params[for_page].presence || "#{controller_name}_#{action_name}"
  end

end
