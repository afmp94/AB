class NylasApi::Admin

  def initialize(account_id=nil)
    connect_to_nylas
    @account_id = account_id
  end

  def api
    @nylas
  end

  def upgrade
    result = false

    if account = @nylas.accounts.find(@account_id)
      begin
        result = account.upgrade
        Rails.logger.info "[NYLAS.admin] Account #{@account_id} upgraded"
        result
      rescue Nylas::AccessDenied => e
        HandleApplicationErrorService.new(e, true).process
      end
    end

    result
  end

  def downgrade
    result = false

    if account = @nylas.accounts.find(@account_id)
      begin
        result = account.downgrade
        Rails.logger.info "[NYLAS.admin] Account #{@account_id} downgraded"
        result
      rescue Nylas::InternalError => e
        HandleApplicationErrorService.new(e, true).process
      rescue Nylas::AccessDenied => e
        HandleApplicationErrorService.new(e, true).process
      end
    end

    result
  end

  def billing_status_cancelled?
    account = @nylas.accounts.find(@account_id)
    account.billing_state == "cancelled"
  end

  def webhooks
    Rails.logger.info "@nylas: #{@nylas.inspect}"
    @nylas.webhooks.map(&:to_h)
  end

  private

  def connect_to_nylas
    @nylas ||= Nylas::API.new(
      app_id: Rails.application.secrets.nylas[:id],
      app_secret: Rails.application.secrets.nylas[:secret],
    )
  rescue Nylas::APIError => e
    Rails.logger.warn "[NYLAS.admin] Error connecting to Nylas: #{e}"
    nil
  end

end
