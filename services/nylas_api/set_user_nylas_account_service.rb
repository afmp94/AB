module NylasApi

  class SetUserNylasAccountService

    attr_reader :user

    def initialize(user)
      @user = user
    end

    def process
      update_user!
    rescue Nylas::AccessDenied => e
      HandleApplicationErrorService.new(e, true).process
      false
    rescue Nylas::ResourceNotFound => e
      HandleApplicationErrorService.new(e, true).process
      false
    end

    def nylas_account
      @nylas_account ||= NylasApi::Account.new(user.nylas_token)
    end

    def update_user!
      user.nylas_account_id              = nylas_account.account_id
      user.last_cursor                   = nylas_account.latest_cursor
      user.nylas_connected_email_account = nylas_account.email_address
      user.nylas_sync_status             = nylas_account.sync_status
      user.nylas_account_provider        = nylas_account.provider
      user.save!
    end

  end

end
