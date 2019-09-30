class LeadTransactionCommissionService

  attr_accessor :lead

  def initialize(lead)
    @lead = lead
  end

  def calculate
    Rails.logger.debug "[LEAD.calculation] Calculating via LeadTransactionCommissionService for lead: #{lead.name}"
    if lead.client_type == "Buyer"
      buyer_commission
    elsif lead.client_type == "Seller"
      seller_commission
    end
  end

  private

  def buyer_commission
    case lead.status
    when 0..2
      set_default_values
    when 3
      buyer_contract_commission
    when 4
      closed_buyer_contract_commission
    end
  end

  def seller_commission
    case lead.status
    when 1..2
      set_values_from_listing
    when 3..4
      set_values_from_listing_contract
    else
      set_default_values
    end
  end

  def buyer_contract_commission
    if has_accepted_buyer_contract?
      set_values_from_buyer_contract
    else
      set_default_values
    end
  end

  def closed_buyer_contract_commission
    if has_accepted_buyer_contract?
      set_values_from_buyer_contract
    end
  end

  def set_default_values
    lead.displayed_commission_type = "Percentage"
    lead.displayed_commission_rate = 2.5
  end

  def set_values_from_buyer_contract
    contract = lead.accepted_buyer_contract
    lead.displayed_commission_type = contract.commission_type
    lead.displayed_commission_rate = contract.commission_percentage_buyer_side
    lead.displayed_commission_fee = contract.commission_fee_buyer_side
    lead.displayed_additional_fees = contract.additional_fees
  end

  def set_values_from_listing
    property = lead.listing_property
    lead.displayed_commission_type = commission_type_from_listing(property)
    lead.displayed_commission_rate = commission_percentage_from_listing(property)
    lead.displayed_commission_fee = property.commission_fee
  end

  def set_values_from_listing_contract
    if has_accepted_listing_contract?
      contract = lead.accepted_listing_contract
      lead.displayed_commission_type = contract.commission_type
      lead.displayed_commission_rate = contract.commission_rate
      lead.displayed_commission_fee = contract.commission_flat_fee
      lead.displayed_additional_fees = contract.additional_fees
    else
      set_values_from_listing
    end
  end

  def has_accepted_buyer_contract?
    lead.accepted_buyer_contract.present?
  end

  def has_accepted_listing_contract?
    lead.accepted_listing_contract.present?
  end

  def commission_type_from_listing(property)
    if property.commission_type.blank?
      "Percentage"
    else
      property.commission_type
    end
  end

  def commission_percentage_from_listing(property)
    if property.commission_percentage.blank?
      2.5
    else
      property.commission_percentage
    end
  end

end
