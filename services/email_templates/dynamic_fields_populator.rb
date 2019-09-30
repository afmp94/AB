class EmailTemplates::DynamicFieldsPopulator

  def initialize(message_body, contact)
    @contact = contact
    @message_body = message_body
    @replacements = replacements_hash(@contact)
  end

  def populate
    @replacements.each { |replacement| @message_body.gsub!(replacement[0], replacement[1]) }
    @message_body
  end

  def replacements_hash(contact)
    [
      ["{{ first_name }}", contact.first_name || "Hey"],
      ["{{ last_name }}", contact.last_name.to_s],
      ["{{ title }}", contact.title.to_s],
      ["{{ email_address }}", contact.email.to_s],
      ["{{ company }}", contact.company.to_s],
      ["{{ phone_number }}", contact.phone_number.to_s]
    ]
  end

end
