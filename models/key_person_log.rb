# == Schema Information
#
# Table name: key_person_logs
#
#  contract_id            :integer
#  created_at             :datetime         not null
#  dotloop_participant_id :integer
#  id                     :bigint(8)        not null, primary key
#  is_deleted             :boolean          default(FALSE)
#  is_updated             :boolean          default(FALSE)
#  lead_id                :integer
#  participant_id         :integer
#  updated_at             :datetime         not null
#

class KeyPersonLog < ApplicationRecord

  belongs_to :lead

end
