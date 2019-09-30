json.leads @leads do |lead|
  json.extract!(
    lead,
    :id,
    :display_full_name,
  )
  json.email lead.contact.email
  json.phone_number number_to_phone(lead.contact.phone_number, area_code: true)
  json.last_contacted_date cal_date(lead.contact.last_contacted_date)
  json.initials lead.contact.initials
  json.avatar_color lead.contact.avatar_color
end
