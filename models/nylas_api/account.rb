class NylasApi::Account

  attr_reader :token

  def initialize(token)
    @token = token
  end

  def retrieve
    if nylas_account.nil?
      nil
    else
      nylas_account
    end
  end

  def account_id
    account_object.try(:account_id)
  end

  def name
    account_object.try(:name)
  end

  def email_address
    account_object.try(:email_address)
  end

  def provider
    account_object.try(:provider)
  end

  def organizational_unit
    account_object.try(:organizational_unit)
  end

  def sync_status
    status =  account_object.try(:sync_state)

    if status == "running"
      # Note: Need to check why there are different statuses comming from
      # Nylas. Webhook event statuses and normal sync statuses of the account
      # object are not same. So adding this hack temporarily.

      return User::NYLAS_ACCOUNT_SYNC_STATUSES["account.running"]
    end

    status
  end

  def latest_cursor
    nylas_account&.deltas&.latest_cursor
  end

  private

  def nylas_account
    if @token.nil?
      return nil
    else
      @_nylas_account ||= Nylas::API.new(
        app_id: Rails.application.secrets.nylas[:id],
        app_secret: Rails.application.secrets.nylas[:secret],
        access_token: token
      )
    end
  rescue Nylas::APIError => e
    Rails.logger.error "[NYLAS.account] Error retrieving account: #{e}"
    return nil
  end

  def account_object
    @_account_object ||= nylas_account&.current_account
  rescue Nylas::APIError => e
    Rails.logger.error "[NYLAS.account] Error retrieving account: #{e}"
    return nil
  rescue Nylas::ResourceNotFound => e
    Rails.logger.error "[NYLAS.account] Account not found: #{e}"
    return nil
  end

end
