class LeadCommissionCalculationService

  attr_accessor :lead, :type, :percentage, :fee, :gross_commission

  def initialize(lead)
    @lead = lead
    @gross_commission = @lead.displayed_gross_commission
  end

  def calculate
    deduct_franchise_fee

    get_lead_commission_settings
    Rails.logger.debug "[LEAD.calculation] Calculating for lead: #{lead.name}. Type is #{type || 'nil'}"

    if type == "Percentage"
      calculate_percentage_commission
    elsif type == "Fee"
      calculate_fee_commission
    end
  end

  private

  def deduct_franchise_fee
    if lead.displayed_broker_has_franchise_fee && gross_commission
      franchise_fee = lead.displayed_broker_franchise_fee
      Rails.logger.debug "[LEAD.calculation] Franchise fee: #{franchise_fee}"
      Rails.logger.debug "[LEAD.calculation] Gross commission: #{gross_commission}"
      amount_to_deduct = gross_commission * (franchise_fee / 100)
      Rails.logger.debug "[LEAD.calculation] Deducting franchise fee..."
      Rails.logger.debug "[LEAD.calculation] Original: #{gross_commission} Deduct: #{amount_to_deduct}"
      @gross_commission = gross_commission - amount_to_deduct
    end
  end

  def get_lead_commission_settings
    @type = lead.displayed_broker_commission_type
    @percentage = lead.displayed_broker_commission_percentage
    @fee = lead.displayed_broker_commission_fee
  end

  def calculate_percentage_commission
    if gross_commission && percentage
      Rails.logger.debug "[LEAD.calculation] Gross commission: #{gross_commission}"
      Rails.logger.debug "[LEAD.calculation] Percentage: #{percentage}"
      result = (gross_commission * (percentage.try(:to_f) / 100))
      Rails.logger.debug "[LEAD.calculation] Net commission: #{result}"
      result
    end
  end

  def calculate_fee_commission
    if gross_commission && fee
      net_commission = gross_commission - fee

      if net_commission < 0
        0
      else
        net_commission
      end
    end
  end

end
