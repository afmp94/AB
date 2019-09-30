class CalculateGrossCommissionService

  attr_reader :lead
  attr_accessor :price, :commission_type, :percentage, :fee,
                :referral_type, :referral_percentage, :referral_fee,
                :additional_fees

  def initialize(lead)
    @lead = lead
    get_gross_commission_values
    get_referral_values
  end

  def calculate
    Rails.logger.debug "[LEAD.calculation] Calculating gross commission for #{lead.name}..."
    gross = gross_commission_before_referral_cost
    Rails.logger.debug "[LEAD.calculation] Gross: #{gross}"
    referral = referral_cost.to_f
    Rails.logger.debug "[LEAD.calculation] Referral: #{referral}"
    additional_fees = @additional_fees.to_f
    Rails.logger.debug "[LEAD.calculation] Additional fees: #{additional_fees}"

    if gross
      gross - referral - additional_fees
    end
  end

  def gross_commission_before_referral_cost
    if percentage_commission?
      Rails.logger.debug "[LEAD.calculation] Commission type is percentage"
      calculate_gross_commission_from_percentage
    elsif fee_commission?
      Rails.logger.debug "[LEAD.calculation] Commission type is fee"
      fee
    else
      Rails.logger.debug "[LEAD.calculation] Commission has no type"
      nil
    end
  end

  def referral_cost
    if percentage_referral?
      calculate_referral_cost_from_percentage(gross_commission_before_referral_cost).to_f
    elsif fee_referral?
      referral_fee.to_f
    else
      0
    end
  end

  private

  def get_gross_commission_values
    @price = lead.displayed_price
    Rails.logger.debug "[LEAD.calculation] Displayed price: #{@price}"
    @commission_type = lead.displayed_commission_type
    Rails.logger.debug "[LEAD.calculation] Displayed commission type: #{@commission_type}"
    @percentage = lead.displayed_commission_rate
    Rails.logger.debug "[LEAD.calculation] Displayed commission rate: #{@percentage}"
    @fee = lead.displayed_commission_fee
    Rails.logger.debug "[LEAD.calculation] Displayed commission fee: #{@fee}"
    @additional_fees = lead.displayed_additional_fees
    Rails.logger.debug "[LEAD.calculation] Displayed additional fees:: #{@additional_fees}"
  end

  def get_referral_values
    @referral_type       = lead.displayed_referral_type
    @referral_percentage = lead.displayed_referral_percentage
    @referral_fee        = lead.displayed_referral_fee
  end

  def percentage_commission?
    commission_type == "Percentage"
  end

  def fee_commission?
    commission_type == "Fee"
  end

  def percentage_referral?
    referral_type == "Percentage"
  end

  def fee_referral?
    referral_type == "Fee"
  end

  def calculate_gross_commission_from_percentage
    if price && percentage
      price * (percentage / 100)
    end
  end

  def calculate_referral_cost_from_percentage(gross_commission)
    if gross_commission && referral_percentage
      gross_commission * (referral_percentage / 100)
    end
  end

end
