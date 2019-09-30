# == Schema Information
#
# Table name: white_label_domains
#
#  company_name        :string           not null
#  cors_domain_added   :boolean          default(FALSE)
#  created_at          :datetime         not null
#  domain              :string           not null
#  heroku_domain_added :boolean          default(FALSE)
#  id                  :bigint(8)        not null, primary key
#  logos_added         :boolean          default(FALSE)
#  name                :string           not null
#  primary_color       :string
#  secondary_color     :string
#  tertiary_color      :string
#  updated_at          :datetime         not null
#

class WhiteLabelDomain < ApplicationRecord

  validates :name, :domain, presence: true

end
