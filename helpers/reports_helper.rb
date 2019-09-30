module ReportsHelper

  def handle_listing_row_classes(lead)
    classes = []

    if negative_listing_row?(lead)
      classes << "negative"
    elsif warning_listing_row?(lead)
      classes << "warning"
    end

    classes.join(" ")
  end

  def handle_pending_row_classes(lead)
    classes = []

    if negative_pending_row?(lead)
      classes << "negative"
    elsif warning_pending_row?(lead)
      classes << "warning"
    end

    classes.join(" ")
  end

  def handle_closed_row_classes(lead)
    classes = []

    if warning_closed_row?(lead)
      classes << "warning"
    end

    classes.join(" ")
  end

  def attention_icon
    "<i class='attention icon' data-behavior='popup' data-content='You have missing data'></i>"
  end

  def expired?(date)
    return false if date.nil?

    date < Time.current
  end

  def missing_data?(data)
    data.nil?
  end

  private

  def negative_listing_row?(lead)
    expired?(lead.listing_property&.listing_expires_at)
  end

  def warning_listing_row?(lead)
    lead.listing_property&.listing_expires_at.nil? || lead.displayed_price.nil? || lead.displayed_net_commission.nil?
  end

  def negative_pending_row?(lead)
    expired?(lead.displayed_closing_date_at)
  end

  def warning_pending_row?(lead)
    lead.displayed_price.nil? || lead.displayed_net_commission.nil?
  end

  def warning_closed_row?(lead)
    lead.displayed_closing_date_at.nil? || lead.displayed_price.nil? || lead.displayed_net_commission.nil?
  end

end
