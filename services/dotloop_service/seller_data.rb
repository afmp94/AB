class DotloopService::SellerData

  attr_reader :lead

  def initialize(lead=nil)
    @lead = lead
  end

  def seller_data
    data = {
      "Property Address": property_address_hash,
      "Financials": financial_hash,
      "Contract Dates": seller_contract_dates,
      "Offer Dates": seller_offer_date_data,
      "Contract Info": {
        "Type": contract_type.to_s
      },
      "Referral": seller_referal_data,
      "Listing Information": listing_info_hash,
      "Property": property_hash
    }
    data
  end

  private

  def seller_contract_dates
    {
      "Contract Agreement Date": date_format(offer_accepted_date_at).to_s,
      "Closing Date": date_format(closing_date_at).to_s
    }
  end

  def seller_offer_date_data
    {
      "Offer Date": date_format(offer_accepted_date_at).to_s,
      "Offer Expiration Date": date_format(offer_deadline_at).to_s
    }
  end

  def seller_referal_data
    {
      "Referral %": referral_fee_rate.to_s,
      "Referral Source": lead.try(:lead_source).try(:name).to_s
    }
  end

  def listing_info_hash
    {
      "Expiration Date": date_format(lead.listing_property.listing_expires_at).to_s,
      "Listing Date": date_format(lead.listing_property.original_list_date_at).to_s,
      "Original Price": lead.listing_property.original_list_price.to_s,
      "Current Price": lead.listing_property.list_price.to_s
    }
  end

  def property_address_hash
    {
      "Street Number": seller_street_number.to_s,
      "Street Name": seller_street_number.to_s,
      "Unit Number": seller_street_number.to_s,
      "City": seller_city.to_s,
      "State/Prov": seller_state.to_s,
      "Zip/Postal Code": seller_zip_code.to_s,
      "MLS Number": mls_number.to_s

    }
  end

  def financial_hash
    {
      "Purchase/Sale Price": offer_price.to_s,
      "Sale Commission Rate": commission_percentage_total.to_s,
      "Sale Commission Split % - Buy Side": percent_conversion(commission_percentage_buyer_side.to_s),
      "Sale Commission Split % - Sell Side": percent_conversion(commission_rate.to_s),
      "Sale Commission Total": commission_fee_total.to_s,
      "Sale Commission Split $ - Buy Side": commission_fee_buyer_side.to_s,
      "Sale Commission Split $ - Sell Side": commission_flat_fee.to_s
    }
  end

  def percent_conversion(percent)
    if percent.present?
      percent = "0-" + percent
    end
    percent.to_s
  end

  def property_hash
    {
      "Bedrooms": bedrooms.to_s,
      "Square Footage": sq_feet.to_s,
      "Type": property_type.to_s,
      "Bathrooms": bathrooms.to_s,
      "Lot Size": lot_size.to_s
    }
  end

  def sq_feet
    lead.try(:listing_property).try(:sq_feet)
  end

  def bedrooms
    lead.try(:listing_property).try(:bedrooms)
  end

  def bathrooms
    lead.try(:listing_property).try(:bathrooms)
  end

  def lot_size
    lead.try(:listing_property).try(:lot_size)
  end

  def property_type
    type = lead.try(:listing_property).try(:property_type)
    if type == 0
      "Single Family"
    elsif type == 1
      "Multi-family"
    elsif type == 2
      "Condo"
    elsif type == 3
      "Apartment"
    elsif type == 4
      "Office/Commercial"
    elsif type == 5
      "Land"
    end
  end

  def referral_fee_rate
    lead.try(lead_status).try(:referral_fee_rate)
  end

  def contract_type
    lead.try(lead_status).try(:contract_type)
  end

  def offer_accepted_date_at
    lead.try(lead_status).try(:offer_accepted_date_at)
  end

  def closing_date_at
    lead.try(lead_status).try(:closing_date_at)
  end

  def offer_deadline_at
    lead.try(lead_status).try(:offer_deadline_at)
  end

  def offer_price
    attribute = [1, 2].include?(lead.status) ? "list" : "offer"
    lead.try(lead_status).try("#{attribute}_price".to_sym)
  end

  def commission_percentage_total
    lead.try(lead_status).try(:commission_percentage_total)
  end

  def commission_percentage_buyer_side
    lead.try(lead_status).try(:commission_percentage_buyer_side)
  end

  def commission_rate
    attribute = [1, 2].include?(lead.status) ? "commission_percentage" : "commission_rate"
    lead.try(lead_status).try(attribute.to_sym)
  end

  def commission_fee_total
    lead.try(lead_status).try(:commission_fee_total)
  end

  def commission_fee_buyer_side
    lead.try(lead_status).try(:commission_fee_buyer_side)
  end

  def commission_flat_fee
    lead.try(lead_status).try(:commission_flat_fee)
  end

  def seller_street_number
    if lead.listing_property.present?
      lead.try(:listing_property).try(:address).try(:street)
    end
  end

  def seller_city
    if lead.listing_property.present?
      lead.try(:listing_property).try(:address).try(:city)
    end
  end

  def seller_state
    if lead.listing_property.present?
      lead.try(:listing_property).try(:address).try(:state)
    end
  end

  def seller_zip_code
    if lead.listing_property.present?
      lead.try(:listing_property).try(:address).try(:zip)
    end
  end

  def mls_number
    if lead.listing_property.present?
      lead.try(:listing_property).try(:mls_number)
    end
  end

  def lead_status
    case lead.status
    when 1
      "listing_property".to_sym
    when 2
      "listing_property".to_sym
    when 3
      "accepted_listing_contract".to_sym
    when 4
      "accepted_listing_contract".to_sym
    end
  end

  def date_format(date)
    if date.present?
      date.to_date.strftime("%m/%d/%Y")
    else
      date
    end
  end

end
