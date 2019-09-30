# == Schema Information
#
# Table name: referral_codes
#
#  account_credit_amount_in_cents :integer
#  code                           :string
#  created_at                     :datetime         not null
#  description                    :text
#  expiration_date_at             :date
#  id                             :bigint(8)        not null, primary key
#  limit_acccess_code             :integer          default(1000), not null
#  total_survey_taken_count       :integer          default(0)
#  updated_at                     :datetime         not null
#
# Indexes
#
#  index_referral_codes_on_code  (code) UNIQUE
#

class ReferralCode < ActiveRecord::Base

  MAX_CODE_LENGTH = 7

  after_initialize :init, if: :new_record?

  validates :code, presence: true, length: { maximum: MAX_CODE_LENGTH }
  validates :expiration_date_at, :limit_acccess_code, presence: true
  validates :limit_acccess_code, numericality: { only_integer: true, greater_than: 0 }

  def expired?
    (expiration_date_at <= Time.current.to_date) || (total_survey_taken_count >= limit_acccess_code)
  end

  def expired_for_account_credit?
    expiration_date_at <= Time.current.to_date
  end

  private

  def init
    self.code = generate_code if self.code.nil?
  end

  def generate_code
    loop do
      code = SecureRandom.hex(MAX_CODE_LENGTH / 2)
      break code unless ReferralCode.where(code: code).exists?
    end
  end

end
