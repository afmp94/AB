module StatsHelper

  def stat_block(options={})
    # Required arguments: label, value, columns
    # Optional arguments: link, color_class

    options[:link] = nil unless options[:link].present?
    options[:color_class] = nil unless options[:color_class].present?

    render(partial: "shared/stats/stat_block", locals: options)
  end

  def progress_bar_class(percent_complete)
    if percent_complete == 100
      "success"
    elsif percent_complete > 75
      "danger"
    end
  end

end
