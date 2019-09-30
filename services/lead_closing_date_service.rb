class LeadClosingDateService

  attr_reader :lead

  def initialize(lead)
    @lead = lead
  end

  def calculate
    if lead.client_type == "Buyer"
      Rails.logger.debug "[LEAD.calculation] Setting closing date for buyer lead: #{lead.name}"
      calculate_buyer_closing_date
    elsif lead.client_type == "Seller"
      Rails.logger.debug "[LEAD.calculation] Setting closing date for seller lead: #{lead.name}"
      calculate_seller_closing_date
    end
  end

  private

  def calculate_buyer_closing_date
    Rails.logger.debug "[LEAD.calculation] lead status: #{@lead.status}"
    case @lead.status
    when 0
      calculate_est_close(early_lead_date, 2) || (early_lead_date + 1.year)
    when 1..2
      calculate_est_close(early_lead_date, 2)
    when 3..4
      buyer_contract_date
    end
  end

  def calculate_seller_closing_date
    Rails.logger.debug "[LEAD.calculation] lead status: #{@lead.status}"
    case @lead.status
    when 0
      calculate_est_close(early_lead_date, 2) || (early_lead_date + 1.year)
    when 1
      calculate_est_close(early_lead_date, 2)
    when 2
      calculate_est_close(listing_date)
    when 3..4
      listing_contract_date
    end
  end

  def calculate_est_close(base_date, months_added=0)
    if base_date && lead.timeframe
      (base_date + (Lead::TIMEFRAMES_IN_INTEGERS[lead.timeframe] + months_added).months)
    end
  end

  def early_lead_date
    lead.incoming_lead_at || lead.created_at || Time.zone.now
  end

  def listing_date
    lead.listing_property.original_list_date_at || lead.incoming_lead_at || lead.created_at
  end

  def buyer_contract_date
    if contract = lead.accepted_buyer_contract
      contract.closing_date_at
    end
  end

  def listing_contract_date
    Rails.logger.debug "[LEAD.calculation] contracts: #{lead.contracts.count}"
    Rails.logger.debug "[LEAD.calculation] contracts: #{lead.contracts.first.inspect}"
    Rails.logger.debug "[LEAD.calculation] contract: #{lead.accepted_listing_contract.inspect}"
    if contract = lead.accepted_listing_contract
      Rails.logger.debug "[LEAD.calculation] contract closing date: #{contract.closing_date_at}"
      contract.closing_date_at
    end
  end

end
