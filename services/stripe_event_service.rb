class StripeEventService

  def initialize(event)
    @event = event
  end

  def customer_subscription_deleted
    if subscription.present?
      Cancellation.new(subscription: subscription).process
    end
  end

  def customer_subscription_updated
    if subscription.present?
      subscription.write_plan(sku: stripe_subscription.items.first.plan.id)
      SubscriptionUpcomingInvoiceUpdater.new([subscription]).process
    end
  end

  private

  def subscription
    if subscription = Subscription.find_by(stripe_id: stripe_subscription.id)
      subscription
    else
      message        = "No subscription found in '#{Rails.env.upcase}' environment for #{stripe_subscription.id}"
      event_metadata = @event.to_hash

      Rails.logger.info message

      Honeybadger.notify(
        error_message: message,
        error_class: "StripeEvent",
        parameters: event_metadata
      )

      AdminMailer.notify_stripe_event_error(message, event_metadata).deliver

      nil
    end
  end

  def stripe_subscription
    @event.data.object
  end

end
