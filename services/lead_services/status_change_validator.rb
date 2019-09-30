class LeadServices::StatusChangeValidator

  attr_accessor :lead, :old_status, :new_status, :type

  def initialize(lead)
    @lead = lead
    @old_status = lead.status
    @type = lead.client_type
  end

  def validate(new_status)
    @new_status = new_status
    Rails.logger.info("[LEAD.status_change_validator] Lead: #{lead.name}")
    Rails.logger.info("[LEAD.status_change_validator] Client type is #{type}")
    Rails.logger.info("[LEAD.status_change_validator] Changing from #{old_status} to #{new_status}")
    Rails.logger.info("[LEAD.status_change_validator] Validating...")

    return true if no_status_change?

    if type == "Buyer"
      validate_buyer_changes
    else
      validate_seller_changes
    end
  end

  private

  def no_status_change?
    if old_status == new_status
      Rails.logger.info("[LEAD.status_change_validator] True: no status change")
      true
    else
      false
    end
  end

  def validate_buyer_changes
    Rails.logger.info("[LEAD.status_change_validator] Detected buyer...")
    case new_status
    when 3
      buyer_to_pending?
    when 4
      buyer_to_closed?
    else
      Rails.logger.info("[LEAD.status_change_validator] True")
      true
    end
  end

  def validate_seller_changes
    Rails.logger.info("[LEAD.status_change_validator] Detected seller...")
    case new_status
    when 3
      seller_to_pending?
    when 4
      seller_to_closed?
    else
      Rails.logger.info("[LEAD.status_change_validator] True")
      true
    end
  end

  def seller_to_pending?
    has_accepted_contract?
  end

  def seller_to_closed?
    has_accepted_contract?
  end

  def buyer_to_pending?
    has_accepted_contract?
  end

  def buyer_to_closed?
    has_accepted_contract?
  end

  def has_accepted_contract?
    if lead.contracts.accepted.present?
      Rails.logger.info("[LEAD.status_change_validator] Has accepted contract...")
      true
    else
      Rails.logger.info("[LEAD.status_change_validator] False: does not have an accepted contract")
      false
    end
  end

end
