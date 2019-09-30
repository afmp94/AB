# == Schema Information
#
# Table name: personal_links
#
#  created_at :datetime         not null
#  id         :bigint(8)        not null, primary key
#  title      :string
#  updated_at :datetime         not null
#  url        :string
#  user_id    :bigint(8)
#
# Indexes
#
#  index_personal_links_on_user_id  (user_id)
#

class PersonalLink < ActiveRecord::Base

  LIMIT = 8

  BASIC_URL_REGEX = /(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?/ix

  belongs_to :user

  validates :title, :url, presence: true
  validates :title, length: { maximum: 10 }

  validates(
    :url,
    format: { with: BASIC_URL_REGEX, message: "Please enter valid URL." },
    unless: Proc.new { |model| model.url.blank? }
  )

  validate :check_limit

  private

  def check_limit
    if user.personal_links.count >= 8
      errors.add(:base, "You can not add personal links more than 8!")
    end
  end

end
