class SubscriptionFulfillment

  def initialize(user, plan)
    @user = user
    @plan = plan
  end

  def fulfill
    update_next_invoice_info
  end

  private

  def update_next_invoice_info
    SubscriptionUpcomingInvoiceUpdater.new([@user.subscription]).process
  end

end
