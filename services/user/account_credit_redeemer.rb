class User::AccountCreditRedeemer

  attr_reader :user, :valid_account_credits

  def initialize(user_id)
    @user = User.find(user_id)
    @valid_account_credits = user.valid_account_credits
  end

  def process
    if valid_account_credits.present?
      create_invoice_items_for_account_credits
      invoice = create_invoice
      pay_invoice(invoice)
      update_account_balance
      mark_account_credits_as_redeemed
    end
  end

  private

  def create_invoice_items_for_account_credits
    valid_account_credits.each do |account_credit|
      Stripe::InvoiceItem.create(
        customer: user.stripe_customer_id,
        amount: -account_credit.amount,
        description: account_credit.description,
        currency: "usd",
        discountable: false,
        subscription: user.subscription.stripe_id
      )
    end
  end

  def create_invoice
    Stripe::Invoice.create(
      customer: user.stripe_customer_id,
      subscription: user.subscription.stripe_id
    )
  end

  def pay_invoice(invoice)
    invoice = Stripe::Invoice.retrieve(invoice.id)
    invoice.pay
  end

  def update_account_balance
    account_balance = valid_account_credits.sum(:amount)
    if account_balance.nonzero?
      account_balance_in_dollar = account_balance / 100
      user.subscription.update!(account_balance: account_balance_in_dollar)
    end
  end

  def mark_account_credits_as_redeemed
    valid_account_credits.update_all(
      redeemed: true,
      redeemed_at: Time.current
    )
  end

end
