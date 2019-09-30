class LeadUpdateDisplayedFieldsService

  attr_accessor :lead

  def initialize(lead)
    @lead = lead
  end

  def update_all
    Rails.logger.debug "[LEAD.calculation] Updating all via LeadUpdateDisplayedFieldsService for lead: #{lead.name}"
    calculate_all
    lead.save!
  end

  def calculate_all
    Rails.logger.debug "[LEAD.calculation] Calculating all via LeadUpdateDisplayedFieldsService for lead: #{lead.name}"
    calculate_closing_date
    calculate_price
    calculate_commission
    calculate_referral
    calculate_gross_commission
    calculate_broker_split
    calculate_net_commission
  end

  def update_commission_data
    calculate_broker_split
    calculate_net_commission
    lead.save!
  end

  private

  def calculate_closing_date
    lead.displayed_closing_date_at = LeadClosingDateService.new(lead).calculate
  end

  def calculate_price
    lead.displayed_price = LeadPriceCalculationService.new(lead).calculate
  end

  def calculate_commission
    LeadTransactionCommissionService.new(lead).calculate
  end

  def calculate_referral
    LeadReferralValuesService.new(lead).calculate
  end

  def calculate_gross_commission
    lead.displayed_gross_commission = CalculateGrossCommissionService.new(lead).calculate
  end

  def calculate_broker_split
    CommissionSplitCalculationService.new(lead).calculate
  end

  def calculate_net_commission
    lead.displayed_net_commission = LeadCommissionCalculationService.new(lead).calculate
  end

end
