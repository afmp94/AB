class ImportGoogleContactsService

  attr_reader :user, :google_contacts

  def initialize(user_id, google_contacts)
    @user = User.find(user_id)
    @google_contacts = google_contacts
  end

  def process
    if !@google_contacts.empty?
      @google_contacts.each do |google_contact|
        if unique_contact?(google_contact)
          Util.log "SAVING GOOGLE API CONTACT -> #{google_contact}"
          save_contact(google_contact)
        end
      end
      user.update!(imported_google_contacts: true)
    end
  end

  def unique_contact?(google_contact)
    @user.contacts.find_by(google_api_contact_id: google_contact[:id]).nil?
  end

  def save_contact(google_contact)
    new_email_addresses = []
    new_phone_numbers   = []
    new_addresses       = []

    new_contact = Contact.new.tap do |_new_contact|
      _new_contact.user                  = @user
      _new_contact.created_by_user       = @user
      _new_contact.first_name            = google_contact[:first_name]
      _new_contact.last_name             = google_contact[:last_name]
      _new_contact.google_api_contact_id = google_contact[:id]

      if _new_contact.first_name.blank? && _new_contact.last_name.blank?
        _new_contact.name = google_contact[:name]
      end

      google_contact[:emails].map do |google_email|
        new_email = _new_contact.email_addresses.new.tap do |_new_email|
          _new_email.email_type = get_email_type(google_email[:name])
          _new_email.email = google_email[:email]
        end

        new_email_addresses << new_email
      end

      google_contact[:phone_numbers].map do |google_phone_number|
        number = _new_contact.phone_numbers.new.tap do |_number|
          _number.number = get_number_type(google_phone_number[:number])
          _number.number_type = google_phone_number[:name]
        end

        new_phone_numbers << number
      end

      google_contact[:addresses].each do |google_address|
        new_address = _new_contact.addresses.new.tap do |_address|
          _address.street = google_address[:address_1]
          _address.city = google_address[:city]
          _address.state = google_address[:region]
          _address.zip = google_address[:postcode]
          _address.county = google_address[:country]
        end

        new_addresses << new_address
      end

      if google_contact[:company]
        _new_contact.company = google_contact[:company]
      end

      if google_contact[:position]
        _new_contact.profession = google_contact[:position]
      end

      if google_contact[:birthday]
        _new_contact.birthday = google_contact[:birthday]
      end

    end

    new_contact.email_addresses = new_email_addresses
    new_contact.phone_numbers   = new_phone_numbers
    new_contact.addresses       = new_addresses

    new_contact.save
  end

  def get_number_type(google_number_type)
    type = google_number_type

    PhoneNumber::NUMBER_TYPES.each do |number_type|
      if google_number_type.downcase.include?(number_type.downcase)
        type = number_type
        break
      end
    end

    type
  end

  def get_email_type(google_email_type)
    type = google_email_type

    EmailAddress::EMAIL_TYPES.each do |email_type|
      if google_email_type.downcase.include?(email_type.downcase)
        type = email_type
        break
      end
    end

    type
  end

end
