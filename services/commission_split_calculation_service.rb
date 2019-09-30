class CommissionSplitCalculationService

  attr_reader :user, :gross_commission
  attr_accessor :lead, :type, :percentage, :fee, :has_alt_split,
                :alt_percentage, :has_cap, :cap, :closed_ytd

  def initialize(lead)
    @lead = lead
    @user = @lead.user
    @gross_commission = @lead.displayed_gross_commission
  end

  def calculate
    Rails.logger.debug "[LEAD.commission_split_calculation] Calculating commission split for #{lead.name}..."
    return if @user.nil?

    if @lead.displayed_broker_commission_custom
      Rails.logger.debug "[LEAD.calculation] Using this lead's custom broker commission settings"
      Rails.logger.debug "[LEAD.calculation] Type: #{@lead.displayed_broker_commission_type}"
      Rails.logger.debug "[LEAD.calculation] Fee: #{@lead.displayed_broker_commission_fee}"
      Rails.logger.debug "[LEAD.calculation] Percentage: #{@lead.displayed_broker_commission_percentage}"
      clear_displayed_franchise_fee_fields
    else
      set_franchise_fee_fields

      if exceeded_transaction_cap?
        set_no_commission_expense
      else
        set_commission_expense_fields
      end
    end
  end

  private

  def clear_displayed_franchise_fee_fields
    @lead.displayed_broker_has_franchise_fee = false
    @lead.displayed_broker_franchise_fee = 0
  end

  def set_franchise_fee_fields
    get_user_franchise_fee_settings
    Rails.logger.debug "[LEAD.calculation] Setting franchise fee. Has franchise fee? #{@has_franchise_fee}"
    @lead.displayed_broker_has_franchise_fee = @has_franchise_fee
    @lead.displayed_broker_franchise_fee     = @franchise_fee
  end

  def exceeded_transaction_cap?
    get_user_commission_cap_settings

    if has_cap && cap
      closed_ytd >= cap
    else
      false
    end
  end

  def set_no_commission_expense
    @lead.displayed_broker_commission_type = "Fee"
    @lead.displayed_broker_commission_fee = 0
  end

  def set_commission_expense_fields
    get_user_commission_type_settings

    if type_is_percentage_split?
      set_lead_commission_as_percentage
    elsif type_is_flat_fee?
      set_lead_to_fee_or_alt_percentage
    end
  end

  def set_lead_to_fee_or_alt_percentage
    get_user_commission_fee_settings

    if use_alternative_split?
      set_lead_commission_as_alt_percentage
    else
      set_lead_commission_as_fee
    end
  end

  def set_lead_commission_as_percentage
    Rails.logger.debug "[LEAD.calculation] Setting lead commission as percentage"
    get_user_commission_percentage_settings

    @lead.displayed_broker_commission_type = "Percentage"
    @lead.displayed_broker_commission_percentage = percentage
  end

  def set_lead_commission_as_alt_percentage
    Rails.logger.debug "[LEAD.calculation] Setting lead commission as alternative percentage"
    @lead.displayed_broker_commission_type = "Percentage"
    @lead.displayed_broker_commission_percentage = alt_percentage_agent_side
  end

  def set_lead_commission_as_fee
    Rails.logger.debug "[LEAD.calculation] Setting lead commission as fee"
    @lead.displayed_broker_commission_type = "Fee"
    @lead.displayed_broker_commission_fee = fee
  end

  def type_is_percentage_split?
    type == "Percentage"
  end

  def type_is_flat_fee?
    type == "Fee"
  end

  def use_alternative_split?
    if has_alt_split && commission_after_broker_fee && commission_after_alternative_split
      Rails.logger.debug "[LEAD.calculation] Checking alternative split"
      Rails.logger.debug "[LEAD.calculation] Commission after broker fee: #{commission_after_broker_fee}"
      Rails.logger.debug "[LEAD.calculation] Commission after alt split: #{commission_after_alternative_split}"
      result = commission_after_broker_fee < commission_after_alternative_split
      Rails.logger.debug "[LEAD.calculation] Use alternative split? #{result}"
      result
    else
      Rails.logger.debug "[LEAD.calculation] Has alt split: #{has_alt_split || 'nil'}"
      Rails.logger.debug "[LEAD.calculation] Commission after broker fee: #{commission_after_broker_fee || 'nil'}"
      Rails.logger.debug "[LEAD.calculation] Commission after alt split: #{commission_after_alternative_split || 'nil'}"
      Rails.logger.debug "[LEAD.calculation] Use alternative split? FALSE FALSE FALSE"
      false
    end
  end

  def commission_after_alternative_split
    if gross_commission && alt_percentage
      gross_commission * (alt_percentage_agent_side / 100)
    end
  end

  def commission_after_broker_fee
    if gross_commission && fee
      gross_commission - fee
    end
  end

  def get_user_franchise_fee_settings
    @has_franchise_fee = user.franchise_fee
    @franchise_fee     = user.franchise_fee_per_transaction
  end

  def get_user_commission_type_settings
    @type           = user.commission_split_type
  end

  def get_user_commission_percentage_settings
    @percentage     = user.agent_percentage_split
  end

  def get_user_commission_fee_settings
    @fee            = user.broker_fee_per_transaction
    @has_alt_split  = user.broker_fee_alternative
    @alt_percentage = user.broker_fee_alternative_split
  end

  def get_user_commission_cap_settings
    @has_cap        = user.per_transaction_fee_capped
    @cap            = user.transaction_fee_cap
    @closed_ytd     = user.number_of_closed_leads_YTD
  end

  def alt_percentage_agent_side
    if alt_percentage
      100 - alt_percentage
    end
  end

end
