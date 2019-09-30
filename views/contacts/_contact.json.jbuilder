json.extract!(
  contact,
  :id,
  :first_name,
  :name,
  :last_name,
  :grade,
  :grade_to_s,
  :phone_number,
  :email,
  :created_at,
  :updated_at,
  :profession,
  :company,
  :initials,
  :avatar_color
)
json.phone_number number_to_phone(contact.phone_number, area_code: true)
json.last_contacted_date cal_date(contact.last_contacted_date)
json.groups contact.contact_groups_by_user(current_user) do |group|
  json.name group
end
