class DotloopService

  attr_reader :lead

  def initialize(lead=nil)
    @lead = lead
  end

  def data_for_seller(status, current_user, _template_id)
    data = {
      "name":  @lead.contact.name,
      "transactionType": "LISTING_FOR_SALE",
      "status": status,
      "streetName": @lead.listing_address_street.tr("0-9", ""),
      "streetNumber": @lead.listing_address_street.gsub(/[^0-9,.]/, ""),
      "unit": "12",
      "city": @lead.listing_address_city,
      "zipCode": @lead.listing_address_zip,
      "state": @lead.listing_address_state,
      "participants": [
        {
          "fullName": current_user.name,
          "email": current_user.email,
          "role": "LISTING_AGENT"
        },
        {
          "fullName": @lead.contact.name,
          "email": @lead.contact.email,
          "role": "SELLER"
        }
      ]
    }
    # if lead_status_pending_or_closed?
    #   lead_seller_accepted_contract(data)
    # end
    data
  end

  def data_for_buyer(status, current_user, _template_id)
    data = {
      "name": buyer_name(status),
      "transactionType": "PURCHASE_OFFER",
      "status": status,
      "streetName": buyer_street_name,
      "streetNumber": buyer_street_number,
      "unit": "12",
      "city": buyer_city,
      "zipCode": buyer_zip_code,
      "state": buyer_state,
      "participants": [
        {
          "fullName": current_user.name,
          "email": current_user.email,
          "role": "BUYING_AGENT"
        },
        {
          "fullName": @lead.contact.name,
          "email": @lead.contact.email,
          "role": "BUYER"
        }
      ]
    }
    # if lead_status_pending_or_closed?
    #   lead_buyer_accepted_contract(data)
    # end
    data
  end

  def lead_status_pending_or_closed?
    lead_status = false
    if @lead.status == 3 || @lead.status == 4
      lead_status = true
    end
    lead_status
  end

  def lead_seller_accepted_contract(data)
    if @lead.accepted_listing_contract&.buyer&.present?
      data[:participants] << {
        "fullName": @lead.accepted_listing_contract.buyer,
        "role": "BUYER"
      }
      data[:participants] << {
        "fullName": @lead.accepted_listing_contract.buyer_agent,
        "role": "BUYING_AGENT"
      }
    end
    data
  end

  def lead_buyer_accepted_contract(data)
    if @lead.accepted_buyer_contract&.seller&.present?
      data[:participants] << {
        "fullName": @lead.accepted_buyer_contract.seller,
        "role": "SELLER"
      }

      data[:participants] << {
        "fullName": @lead.accepted_buyer_contract.seller_agent,
        "role": "LISTING_BROKER"
      }
    end
    data
  end

  def key_people_participants(data)
    @lead.key_people.each do |people|
      data[:participants] << {
        "email": people.contact.email,
        "fullName": people.contact.name,
        "role": key_person_role(people.role_type)
      }
    end
    data = duplicate_email_removal(data)
    data
  end

  def duplicate_email_removal(data)
    arr = []
    data[:participants].flatten.compact.each do |p|
      val = arr.map { |a| a[:email] }.include?(p[:email]) ? { fullName: p[:fullName], role: p[:role] } : p
      arr << val
    end
    data[:participants] = arr
    data
  end

  def key_person_role(role)
    person_role = role.upcase.tr(" ", "_")
    if role == "Buyer's Agent"
      person_role = "BUYING_AGENT"
    elsif role == "Buyer Broker"
      person_role = "BUYING_BROKER"
    elsif role == "Transaction Co-ordinator"
      person_role = "TRANSACTION_COORDINATOR"
    elsif role == "Seller"
      person_role = "LISTING_AGENT"
    elsif role == "Seller's Agent"
      person_role = "LISTING_BROKER"
    end
    person_role
  end

  def buyer_city
    if @lead.accepted_buyer_contract.present?
      city = @lead.try(:accepted_buyer_contract).try(:property).try(:address).try(:city)
    end
    city
  end

  def buyer_zip_code
    if @lead.accepted_buyer_contract.present?
      zip = @lead.try(:accepted_buyer_contract).try(:property).try(:address).try(:zip)
    end
    zip
  end

  def buyer_state
    if @lead.accepted_buyer_contract.present?
      state = @lead.try(:accepted_buyer_contract).try(:property).try(:address).try(:state)
    end
    state
  end

  def buyer_name(status)
    name = @lead.contact.name
    if !(status == "PRE_OFFER" || @lead.accepted_buyer_contract.nil?)
      name = @lead.accepted_buyer_contract.property.name
    end
    name
  end

  def buyer_street_name
    if @lead.accepted_buyer_contract.present?
      @lead.try(:accepted_buyer_contract).try(:property).try(:address).try(:street)
    end
  end

  def buyer_street_number
    if @lead.accepted_buyer_contract.present?
      @lead.try(:accepted_buyer_contract).try(:property).try(:address).try(:street)&.gsub(/[^0-9,.]/, "")
    end
  end

  def client_type_seller_status
    case @lead.status
    when 1
      "PRE_LISTING"
    when 2
      "ACTIVE_LISTING"
    when 3
      "UNDER_CONTRACT"
    when 4
      "SOLD"
    when 6
      "ARCHIVED"
    end
  end

  def clent_type_buyer_status
    case @lead.status
    when 1
      "PRE_OFFER"
    when 2
      "PRE_OFFER"
    when 3
      "UNDER_CONTRACT"
    when 4
      "SOLD"
    end
  end

  def refresh_dotloop_token(current_user)
    status = true
    if current_user.integrations.present?
      integration = current_user.integrations.where(name: "dotloop").first
      refresh_token = integration.refresh_token
      begin
        response = dotloop_auth.refresh_access_token(refresh_token)
        integration.access_token = response["access_token"]
        integration.refresh_token = response["refresh_token"]
        integration.save!
      rescue StandardError
        status = false
      end
    end
    status
  end

  def set_dotloop_client(current_user)
    if current_user.integrations.present?
      access_token = current_user.integrations.where(name: "dotloop").first.access_token
      Dotloop::Client.new(access_token: access_token)
    end
  end

  def dotloop_auth
    Dotloop::Authenticate.new(
      app_id: Rails.application.secrets.dotloop[:app_id],
      app_secret: Rails.application.secrets.dotloop[:app_secret],
      application: "dotloop"
    )
  end

  def linked_to_existing_loop(params, current_user)
    loop_id = params[:loop_id]
    profile_id = params[:profile_id]
    DotloopService.new.refresh_dotloop_token(current_user)
    set_dotloop_client = DotloopService.new.set_dotloop_client(current_user)
    result = HTTParty.get("https://api-gateway.dotloop.com/public/v2/profile/#{profile_id}/loop/#{loop_id}",
                          headers:
                          {
                            "Content-Type" => "application/json",
                            "Authorization" =>  "Bearer #{set_dotloop_client.access_token}"
                          })
    result.parsed_response["data"]
  end

  def requires_templates?(set_dotloop_client, profile_id)
    template = set_dotloop_client.Profile.find(profile_id: profile_id)
    template.requires_template
  end

end
