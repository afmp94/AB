class LeadAttributesCalculationService

  attr_accessor :lead
  attr_reader :user

  def initialize(lead)
    @lead = lead
  end

  def set_lead_name
    Rails.logger.debug "[LEAD.calculation] Setting lead name for lead: #{lead.name}"
    if @lead.client_type == "Buyer"
      set_buyer_name
    elsif @lead.client_type == "Seller"
      set_seller_name
    else
      set_generic_name
    end
  end

  private

  def set_buyer_name
    @lead.name = if @lead.contact.full_name.blank?
                   if @lead.contact.primary_email_address.blank?
                     "Untitled" + " (#{lead.client_type})"
                   elsif @lead.contact.primary_email_address&.email&.blank?
                     "Untitled" + " (#{lead.client_type})"
                   else
                     "#{@lead.contact.primary_email_address&.email&.split('@')&.first} (#{lead.client_type})"
                   end
                 else
                   @lead.contact.full_name + " (#{lead.client_type})"
                 end
  end

  def set_seller_name
    @lead.name = if @lead.listing_address_street.blank?
                   if @lead.contact && @lead.contact.full_name.present?
                     @lead.contact.full_name + " (#{lead.client_type})"
                   elsif @lead.contact && @lead.contact.primary_email_address&.email&.present?
                     @lead.contact.primary_email_address.email.split("@")[0] + " (#{lead.client_type})"
                   else
                     @lead.name = "Untitled" + " (#{lead.client_type})"
                   end
                 elsif @lead.contact.full_name.blank?
                   "#{@lead.contact.primary_email_address&.email&.split('@')&.first} - "\
                   "#{@lead.listing_address_street} #{@lead.listing_address_city} (#{lead.client_type})"
                 else
                   @lead.contact.full_name + " - " + @lead.listing_address_street +
                     " " + @lead.listing_address_city + " (#{lead.client_type})"
                 end
  end

  def set_generic_name
    @lead.name = if @lead.contact.full_name.blank?
                   "#{@lead.contact.full_name} - (Client)"
                 else
                   "Untitled (Client)"
                 end
  end

end
