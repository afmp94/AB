# == Schema Information
#
# Table name: important_dates
#
#  contact_id :integer
#  created_at :datetime         not null
#  date_at    :date
#  date_type  :string
#  id         :integer          not null, primary key
#  name       :string
#  updated_at :datetime         not null
#
# Indexes
#
#  index_important_dates_on_contact_id  (contact_id)
#

class ImportantDate < ActiveRecord::Base

  audited
  belongs_to :contact

  TYPES = %w(
    Birthday
    Anniversary
    Other
  ).freeze

  validates :name, presence: true, if: :"date_at_present?"
  validates :date_at, presence: true, if: :"name_present?"

  def self.for_daily_recap(contact_ids, day, types=nil)
    records = where(contact_id: contact_ids, date_at: day)
    records = records.where(date_type: types) if types.present?

    records
  end

  private

  def date_at_present?
    date_at.present?
  end

  def name_present?
    name.present?
  end

end
