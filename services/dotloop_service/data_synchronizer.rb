class DotloopService::DataSynchronizer

  attr_reader :lead, :current_user

  def initialize(lead=nil, current_user=nil)
    @lead = lead
    @current_user = current_user
  end

  def dotloop_to_agentbright(response)
    lead.transaction do

      contract = Contract.where(lead_id: lead.id).first_or_create(
        offer_price: response.financials.purchase_sale_price.to_i,
        status: "pending_contingencies"
      )
      contract.update(update_contract_hash(response))
      data_creation(response, contract)
    end
  end

  def loop_basic_field_data
    {
      "status": get_loop_status,
      "name": loop_name
    }
  end

  def get_loop_status
    status = DotloopService.new(lead).client_type_seller_status
    if lead.client_type == "Buyer"
      status = DotloopService.new(lead).clent_type_buyer_status
    end
    status
  end

  def loop_name_for_buyer
    name = lead.contact.name
    if !(get_loop_status == "PRE_OFFER" || lead.accepted_buyer_contract.nil?) &&
       lead&.accepted_buyer_contract&.property&.name.present?
      name = lead.accepted_buyer_contract.property.name
    end
    name
  end

  def loop_name_for_seller
    lead.contact.name
  end

  def loop_name
    name = loop_name_for_buyer
    if lead.client_type == "Seller"
      name = loop_name_for_seller
    end
    name
  end

  def agentbright_to_dotloop
    data = {
      "Property Address": property_address_hash,
      "Financials": financial_hash,
      "Contract Dates": contract_date_hash,
      "Offer Dates": offer_date_hash,
      "Contract Info": {
        "Type": contract_type.to_s
      },
      "Referral": referal_hash,
      "Property": property_hash
    }

    data
  end

  def update_loop_details(data, lead, set_dotloop_client)
    require "net/http"
    require "uri"
    require "json"
    loop_id = lead.loop.loop_id
    profile_id = lead.loop.profile_id
    uri = URI.parse("https://api-gateway.dotloop.com/public/v2/profile/#{profile_id}/loop/#{loop_id}/detail")
    request = Net::HTTP::Patch.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{set_dotloop_client.access_token}"

    request.body = data.to_json

    req_options = {
      use_ssl: uri.scheme == "https"
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    response
  end

  def update_loop_status(data, lead, set_dotloop_client)
    require "net/http"
    require "uri"
    require "json"
    loop_id = lead.loop.loop_id
    profile_id = lead.loop.profile_id
    uri = URI.parse("https://api-gateway.dotloop.com/public/v2/profile/#{profile_id}/loop/#{loop_id}")
    request = Net::HTTP::Patch.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{set_dotloop_client.access_token}"

    request.body = data.to_json

    req_options = {
      use_ssl: uri.scheme == "https"
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    response
  end

  private

  def contract_date_hash
    {
      "Contract Agreement Date": date_format(offer_accepted_date_at).to_s,
      "Closing Date": date_format(closing_date_at).to_s
    }
  end

  def offer_date_hash
    {
      "Offer Date": date_format(offer_accepted_date_at).to_s,
      "Offer Expiration Date": date_format(offer_deadline_at).to_s
    }
  end

  def referal_hash
    {
      "Referral %": referral_fee_rate.to_s,
      "Referral Source": lead.try(:lead_source).try(:name).to_s
    }
  end

  def client_type_buyer_status
    case loop_detail["status"]
    when "PRE_OFFER"
      2
    when "UNDER_CONTRACT"
      3
    when "SOLD"
      4
    when "ARCHIVED"
      4
    end
  end

  def client_type_seller_status
    case loop_detail["status"]
    when "PRE_LISTING"
      1
    when "PRIVATE_LISTING"
      2
    when "ACTIVE_LISTING"
      2
    when "UNDER_CONTRACT"
      3
    when "SOLD"
      4
    when "ARCHIVED"
      4
    end
  end

  def loop_detail
    set_dotloop_client = DotloopService.new.set_dotloop_client(current_user)
    loop = set_dotloop_client.Loop.find(profile_id: lead.loop.profile_id, loop_id: lead.loop.loop_id)
    loop
  end

  def data_creation(response, contract)
    property = Property.where(lead_id: lead.id).first || Property.where(id: contract.property_id).first_or_create!
    update_property_and_contract_attrs(property, contract, response)
    lead.update_attributes!(status: send("client_type_#{lead.client_type.downcase}_status".to_sym))
  end

  def update_property_and_contract_attrs(property, contract, response)
    property.update(update_property_hash(response))
    contract.update!(property_id: property.id)
    Address.where(owner_id: property.id).first_or_create!.update(update_address_hash(response))
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
    percent
  end

  def property_address_hash
    {
      "Street Number": buyer_street_number.to_s,
      "Street Name": buyer_street_number.to_s,
      "Unit Number": buyer_street_number.to_s,
      "City": buyer_city.to_s,
      "State/Prov": buyer_state.to_s,
      "Zip/Postal Code": buyer_zip_code.to_s,
      "MLS Number": mls_number.to_s

    }
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
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:property).try(:sq_feet)
    end
  end

  def update_contract_hash(response)
    {
      referral_fee_rate: response.referral.referral_percent,
      contract_type: response.contract_info.type,
      offer_deadline_at: contract_closing_date(response.offer_dates.offer_expiration_date),
      offer_accepted_date_at: contract_closing_date(response.offer_dates.offer_date),
      closing_date_at: contract_closing_date(response.contract_dates.closing_date),
      offer_price: response.financials.purchase_sale_price.to_i
    }.merge(contract_commission_hash(response))
  end

  def contract_closing_date(date)
    if date.present?
      date = Date.strptime(date, "%m/%d/%Y")
    end
    date
  end

  def contract_commission_hash(response)
    contract_hash = {
      commission_flat_fee: response.financials.sale_commission_split_doller_sell_side,
      commission_fee_buyer_side: response.financials.sale_commission_split_doller_buy_side,
      commission_fee_total: response.financials.sale_commission_total,
      commission_percentage_total: response.financials.sale_commission_rate
    }
    # if lead.client_type == "Buyer" || lead_type_status
    contract_hash = contract_hash.merge(commission_and_percentage_hash(response))
    # end
    contract_hash
  end

  def commission_and_percentage_hash(response)
    {
      commission_rate: split_percent_val(response.financials.sale_commission_split_percent_sell_side),
      commission_percentage_buyer_side: split_percent_val(response.financials.sale_commission_split_percent_buy_side)
    }
  end

  def lead_type_status
    val = false
    if lead.client_type == "Seller" && ![1, 2].include?(lead.status)
      val = true
    end
    val
  end

  def split_percent_val(percent)
    if percent.present?
      percent = percent.include?("-") ? percent.split("-")[1] : percent
    end
    percent.to_s
  end

  def update_property_hash(response)
    property_hash = {
      mls_number: response.property_address.mls_number,
      bedrooms: response.property.bedrooms,
      bathrooms: response.property.bathrooms,
      property_type: response.property.type,
      lead_id: lead.id,
      sq_feet: response.property.square_footage,
      lot_size: response.property.lot_size
    }
    # if lead_seller_status
    property_hash = property_hash.merge(commission_hash_for_seller_property(response))
    # end
    property_hash = property_hash.merge(listing_property_hash(response))
    property_hash
  end

  def lead_seller_status
    val = false
    if lead.client_type == "Buyer" || lead.client_type == "Seller" && [1, 2].include?(lead.status)
      val = true
    end
    val
  end

  def commission_hash_for_seller_property(response)
    {
      commission_percentage: split_percent_val(response.financials.sale_commission_split_percent_sell_side),
      commission_percentage_buyer_side: split_percent_val(response.financials.sale_commission_split_percent_buy_side)
    }
  end

  def listing_property_hash(response)
    {
      listing_expires_at: contract_closing_date(response.listing_information.expiration_date),
      original_list_date_at: contract_closing_date(response.listing_information.listing_date),
      original_list_price: response.listing_information.original_price,
      list_price: response.listing_information.current_price
    }
  end

  def update_address_hash(response)
    {
      street: response.property_address.street_name,
      city: response.property_address.city,
      state: response.property_address.state_prov,
      zip: response.property_address.zip_postal_code,
      owner_type: "Property"
    }
  end

  def buyer_street_number
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:property).try(:address).try(:street)
    end
  end

  def buyer_city
    if lead.accepted_buyer_contract.present?
      city = lead.try(:accepted_buyer_contract).try(:property).try(:address).try(:city)
    end
    city
  end

  def buyer_state
    if @lead.accepted_buyer_contract.present?
      state = @lead.try(:accepted_buyer_contract).try(:property).try(:address).try(:state)
    end
    state
  end

  def buyer_zip_code
    if lead.accepted_buyer_contract.present?
      zip = lead.try(:accepted_buyer_contract).try(:property).try(:address).try(:zip)
    end
    zip
  end

  def mls_number
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:property).try(:mls_number)
    end
  end

  def property_type
    type = lead.try(:accepted_buyer_contract).try(:property).try(:property_type)
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

  def offer_price
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:offer_price)
    end
  end

  def commission_percentage_total
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:commission_percentage_total)
    end
  end

  def commission_percentage_buyer_side
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:commission_percentage_buyer_side)
    end
  end

  def commission_rate
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:commission_rate)
    end
  end

  def commission_fee_total
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:commission_fee_total)
    end
  end

  def commission_fee_buyer_side
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:commission_fee_buyer_side)
    end
  end

  def commission_flat_fee
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:commission_flat_fee)
    end
  end

  def offer_accepted_date_at
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:offer_accepted_date_at)
    end
  end

  def closing_date_at
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:closing_date_at)
    end
  end

  def offer_deadline_at
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:offer_deadline_at)
    end
  end

  def contract_type
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:contract_type)
    end
  end

  def referral_fee_rate
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:referral_fee_rate)
    end
  end

  def bedrooms
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:property).try(:bedrooms)
    end
  end

  def bathrooms
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:property).try(:bathrooms)
    end
  end

  def lot_size
    if lead.accepted_buyer_contract.present?
      lead.try(:accepted_buyer_contract).try(:property).try(:lot_size)
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
