class LeadReferralValuesService

  attr_accessor :lead

  def initialize(lead)
    @lead = lead
  end

  def calculate
    case lead.status
    when 0..2
      set_values_from_lead
    when 2..4
      set_values_from_contract
    end
  end

  private

  def set_values_from_lead
    lead.displayed_referral_type       = lead.referral_fee_type
    lead.displayed_referral_percentage = lead.referral_fee_rate
    lead.displayed_referral_fee        = lead.referral_fee_flat_fee
  end

  def set_values_from_contract
    if lead.client_type == "Buyer"
      set_values_from_buyer_contract
    elsif lead.client_type == "Seller"
      set_values_from_listing_contract
    end
  end

  def contract_values(contract)
    lead.displayed_referral_type       = contract.referral_fee_type
    lead.displayed_referral_percentage = contract.referral_fee_rate
    lead.displayed_referral_fee        = contract.referral_fee_flat_fee
  end

  def set_values_from_buyer_contract
    if has_accepted_buyer_contract?
      contract_values(lead.accepted_buyer_contract)
    else
      set_values_from_lead
    end
  end

  def set_values_from_listing_contract
    if has_accepted_listing_contract?
      contract_values(lead.accepted_listing_contract)
    else
      set_values_from_lead
    end
  end

  def has_accepted_buyer_contract?
    lead.accepted_buyer_contract.present?
  end

  def has_accepted_listing_contract?
    lead.accepted_listing_contract.present?
  end

end
