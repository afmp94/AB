class CreditCardsController < ApplicationController

  skip_before_action :redirect_if_subscription_inactive

  def new
    render
  end

  def update
    customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)
    customer.source = params["stripe_token"]

    begin
      customer.save
      CreditCardInfoUpdater.new(user: current_user, stripe_customer: customer).process
      User::AccountCreditRedeemer.new(current_user.id).process
      handle_plan
    rescue Stripe::CardError => error
      redirect_to new_credit_card_path, danger: error.message
    end
  end

  private

  def handle_plan
    if session[:stripe_plan_id]
      current_user.subscription.change_plan(sku: session[:stripe_plan_id])
      session.delete(:stripe_plan_id)
      message = "Plan was successfully changed"
    else
      message = I18n.t("subscriptions.flashes.update.success")
    end

    redirect_to billing_path, notice: message
  end

end
