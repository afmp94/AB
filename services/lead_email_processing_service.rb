class LeadEmailProcessingService

  attr_accessor :contact, :lead, :lead_data, :lead_email, :property, :user

  def initialize(lead_email)
    self.lead_email = lead_email
    self.user = lead_email.find_user_by_recipient!
  end

  def process
    lead_email.process!
    begin
      _process
    rescue StandardError => e
      Util.log_exception(e)
      lead_email.parsing_error!
    end
    lead_email.parsing_attempted!
  end

  private

  def _process
    Util.log "\n[LEAD_EMAIL_PARSER] Processing lead email id: #{lead_email.id}..."
    @lead_data = EmailParser.new(lead_email).parse
    if lead_data.blank?
      Util.log "\n[LEAD_EMAIL_PARSER] parsed lead data is empty"
    elsif lead_source_active?(lead_data[:source])
      handle_lead_source_is_active
    else
      lead_email.source_inactive!
    end
  end

  def lead_source_active?(source)
    self.user.lead_setting.lead_source_active?(source)
  end

  def handle_lead_source_is_active
    lead = build_lead_from_email
    Util.log "[LEAD_EMAIL_PARSER] Saving lead..."
    if lead.save
      lead_email.imported!
    else
      log_lead_error lead
      lead_email.failed!
    end
  end

  def build_lead_from_email
    Util.log "[LEAD_EMAIL_PARSER] Building lead from email..."
    build_contact_record
    build_lead_record
    build_property_record

    if user.lead_setting.forwarding_off?
      @lead.auto_claim(user)
      Util.log "[LEAD_EMAIL_PARSER] Forwarding off. Auto claiming and saving lead..."
      @lead.save!
    end
    @lead
  end

  def build_contact_record
    Util.log "[LEAD_EMAIL_PARSER] Finding/building contact..."
    find_or_build_contact
    build_contact_phone_number
    build_contact_email_address
  end

  def build_lead_record
    lead_type = LeadType.find_or_build_by_name("Real Estate Profile")
    lead_source = LeadSource.find_by(name: lead_data[:lead_source])

    @lead = lead_email.build_lead(
      contact: @contact,
      created_by_user: self.user,
      status: 0,
      client_type: lead_data[:client_type],
      incoming_lead_at: lead_email.date,
      lead_type: lead_type,
      lead_source: lead_source,
      notes: lead_data[:message],
      rental: lead_data[:rental] || false
    )
  end

  def build_property_record
    if lead_data[:client_type] == "Seller"
      build_seller_property
    else
      build_buyer_property
    end

    build_property_address
  end

  def find_or_build_contact
    @contact = Contact.find_from_email(self.user, lead_data[:email_address])
    @contact ||= lead_email.build_contact(
      created_by_user: self.user,
      first_name: lead_data[:first_name],
      last_name: lead_data[:last_name]
    )
  end

  def build_contact_phone_number
    @contact.phone_numbers.build(
      number: lead_data[:phone_number],
      number_type: "Mobile",
      primary: true
    )
  end

  def build_contact_email_address
    @contact.email_addresses.build(
      email: lead_data[:email_address],
      email_type: "Primary",
      primary: true
    )
  end

  def build_seller_property
    @property = @lead.properties.build(seller_property_params)
  end

  def seller_property_params
    {
      list_price: lead_data[:price],
      mls_number: lead_data[:mls_id],
      property_url: lead_data[:property_url],
      notes: lead_data[:message],
      bedrooms: lead_data[:bedrooms],
      bathrooms: lead_data[:bathrooms],
      sq_feet: lead_data[:sq_feet],
      lot_size: lead_data[:lot_size],
      transaction_type: lead_data[:client_type],
      property_type: 0
    }
  end

  def build_buyer_property
    @property = @lead.properties.build(buyer_property_params)
  end

  def buyer_property_params
    {
      list_price: lead_data[:price],
      mls_number: lead_data[:mls_id],
      property_url: lead_data[:property_url],
      notes: lead_data[:message],
      bedrooms: lead_data[:bedrooms],
      bathrooms: lead_data[:bathrooms],
      sq_feet: lead_data[:sq_feet],
      lot_size: lead_data[:lot_size],
      transaction_type: lead_data[:client_type],
      property_type: 0,
      initial_property_interested_in: true,
      level_of_interest: "Interested"
    }
  end

  def build_property_address
    @property.build_address(
      street: lead_data[:address],
      city: lead_data[:city],
      state: lead_data[:state],
      zip: lead_data[:zip]
    )
  end

  def log_lead_error(lead)
    Rails.logger.error "[LEAD_EMAIL_PARSER] Errors: #{lead.errors.full_messages.inspect}"
    Rails.logger.error "[LEAD_EMAIL_PARSER] Lead: #{lead.inspect}"
    Rails.logger.error "[LEAD_EMAIL_PARSER] Contact: #{lead.contact.inspect}"
  end

end
