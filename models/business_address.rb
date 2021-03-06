# == Schema Information
#
# Table name: addresses
#
#  address      :string
#  address_type :string
#  city         :string
#  county       :string
#  created_at   :datetime
#  data         :hstore
#  id           :integer          not null, primary key
#  owner_id     :integer
#  owner_type   :string
#  state        :string
#  street       :string
#  updated_at   :datetime
#  zip          :string
#
# Indexes
#
#  index_addresses_on_city                     (city)
#  index_addresses_on_owner_type_and_owner_id  (owner_type,owner_id)
#

class BusinessAddress < Address
end
