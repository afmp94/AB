# == Schema Information
#
# Table name: quotes
#
#  author     :string
#  created_at :datetime         not null
#  id         :bigint(8)        not null, primary key
#  next       :boolean          default(FALSE)
#  text       :text
#  updated_at :datetime         not null
#

class Quote < ActiveRecord::Base

  default_scope { order("id ASC") }

  after_create :reset_other_quotes

  def self.current
    quote = Quote.find_by(next: true)

    quote = Quote.first if quote.nil?
    set_next_quote(quote) if quote.present?

    quote
  end

  def self.set_next_quote(current_quote)
    future_quote = self.find_by("id > ?", current_quote.id)
    future_quote = Quote.first if future_quote.nil?

    if future_quote
      future_quote.update!(next: true)
      current_quote.update!(next: false)
    end
  end

  def reset_other_quotes
    if next?
      Quote.where("id != ?", self.id).update_all(next: false)
    end
  end

end
