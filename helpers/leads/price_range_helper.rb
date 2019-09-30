module Leads::PriceRangeHelper

  def display_lead_price_range(lead)
    min = lead.min_price_range
    max = lead.max_price_range

    if min && max
      price_range(min, max)
    elsif max && min.nil?
      price_up_to(max)
    else
      "Not Set"
    end
  end

  private

  def price_range(min, max)
    if range_under_a_million?(min, max)
      "$#{price_in_k(min)}-$#{price_in_k(max)}k"
    elsif range_over_a_million?(min, max)
      "$#{price_in_m(min)}-$#{price_in_m(max)}m"
    elsif range_straddling_a_million?(min, max)
      "$#{price_in_k(min)}k-$#{price_in_m(max)}m"
    end
  end

  def price_up_to(max)
    if max >= 1_000_000
      "up to $#{price_in_m(max)}m"
    else
      "up to $#{price_in_k(max)}k"
    end
  end

  def price_in_k(price)
    number_with_precision(price / 1000, precision: 0).to_s
  end

  def price_in_m(price)
    (price / 1_000_000.0).to_s
  end

  def range_under_a_million?(min, max)
    min < 1_000_000 && max < 1_000_000
  end

  def range_over_a_million?(min, max)
    min >= 1_000_000 && max >= 1_000_000
  end

  def range_straddling_a_million?(min, max)
    min < 1_000_000 && max >= 1_000_000
  end

end
