class SubscriptionsController < ApplicationController

  before_action :must_be_subscription_owner, only: [:edit, :update]
  skip_before_action :redirect_if_subscription_inactive
  before_action :check_credit_card, only: :update

  def new
    @landing_page = LandingPage.new
  end

  def edit
    @catalog = Catalog.new
  end

  def update
    if current_user.subscription.change_plan(sku: params[:plan_id])
      redirect_to(
        profile_path,
        success: I18n.t("subscriptions.flashes.change.success")
      )
    else
      redirect_to(
        profile_path,
        warning: "Please add a card."
      )
    end
  end

  private

  def check_credit_card
    customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)

    if customer.sources.data.first.nil?
      session[:stripe_plan_id] = params[:plan_id]
      redirect_to new_credit_card_path and return
    end
  end

end
