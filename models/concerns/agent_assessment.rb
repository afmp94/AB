module AgentAssessment

  def save_with_payment(user_params, stripe_card_token)
    if self.valid? && stripe_card_token.present?
      customer = Stripe::Customer.create(
        description: "Agent assessment #{user_params['email']}",
        card: stripe_card_token,
        email: user_params["email"]
      )

      Stripe::Charge.create(
        amount: 4900, # $49 in 'cents'
        currency: "usd",
        customer: customer.id
      )

      self.stripe_customer_id = customer.id
    end

    update(user_params)
  rescue Stripe::InvalidRequestError => e
    logger.error "Stripe error while creating customer #{e.message}"
    errors.add base: "There was a problem with your credit card"
    false
  end

end
