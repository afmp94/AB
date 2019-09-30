class LeadPriceCalculationService

  attr_reader :lead

  def initialize(lead)
    @lead = lead
  end

  def calculate
    Rails.logger.debug "[LEAD.calculation] Calculating price via LeadPriceCalculationService for lead: #{lead.name}"
    if lead.client_type == "Buyer"
      buyer_price
    elsif lead.client_type == "Seller"
      seller_price
    end
  end

  private

  def buyer_price
    case lead.status
    when 0..3
      if has_accepted_contract_with_price?
        lead.accepted_buyer_contract.offer_price
      else
        estimated_buyer_price
      end
    when 4
      buyer_contract_closing_price
    end
  end

  def seller_price
    case lead.status
    when 0..2
      listing_price
    when 3
      listing_contract_price
    when 4
      closed_listing_price
    else
      closed_listing_price
    end
  end

  def has_accepted_contract_with_price?
    lead.accepted_buyer_contract && lead.accepted_buyer_contract.offer_price
  end

  def estimated_buyer_price
    if has_min_and_max?
      (lead.min_price_range + lead.max_price_range) / 2.0
    elsif has_only_max?
      lead.max_price_range * 0.8
    elsif lead.prequalification_amount
      lead.prequalification_amount
    elsif has_only_min?
      lead.min_price_range
    end
  end

  def has_min_and_max?
    lead.min_price_range && lead.max_price_range
  end

  def has_only_max?
    lead.min_price_range.nil? && lead.max_price_range
  end

  def has_only_min?
    lead.min_price_range && lead.max_price_range.nil?
  end

  def buyer_contract_closing_price
    if contract = lead.accepted_buyer_contract
      if price = contract.closing_price
        price
      end
    end
  end

  def listing_price
    if list_price = lead.listing_list_price
      list_price
    else
      lead.try(:listing_property).try(:initial_agent_valuation)
    end
  end

  def listing_contract_price
    if contract = lead.accepted_listing_contract
      contract.offer_price
    else
      listing_price
    end
  end

  def closed_listing_price
    if has_accepted_listing_contract_with_closing_price?
      lead.accepted_listing_contract.closing_price
    elsif has_accepted_listing_contract_with_offer_price?
      lead.accepted_listing_contract.offer_price
    else
      listing_price
    end
  end

  def has_accepted_listing_contract_with_closing_price?
    if contract = lead.accepted_listing_contract
      contract.closing_price.present?
    end
  end

  def has_accepted_listing_contract_with_offer_price?
    if contract = lead.accepted_listing_contract
      contract.offer_price.present?
    end
  end

end
