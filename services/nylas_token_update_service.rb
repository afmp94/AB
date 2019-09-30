class NylasTokenUpdateService

  def update
    return unless more_than_24_hours_since_last_update?

    User.all.each do |user|
      if user_needs_upgrade_from_trial?(user)
        upgrade_nylas_account(user)
      elsif user_needs_downgrade_from_active?(user)
        downgrade_nylas_account(user)
      end
    end
  end

  private

  def more_than_24_hours_since_last_update?
    last_run = Rails.application.config.nylas_token_update_service_last_run
    Time.current > (Time.at(last_run).to_datetime + 1.day)
  end

  def set_last_run_time
    Rails.applicationconfig.nylas_token_update_service_last_run = Time.current.to_i
  end

  def user_needs_upgrade_from_trial?(user)
    user.nylas_token && user.nylas_account_status == "trialing" &&
      trial_began_more_than_28_days_ago(user)
  end

  def user_needs_downgrade_from_active?(user)
    user.nylas_token && user.nylas_account_status == "active" &&
      user.inactive_subscription.present? &&
      inactive_for_more_than_30_days(user.inactive_subscription)
  end

  def trial_began_more_than_28_days_ago(user)
    if trial_started_at = user.nylas_trial_status_set_at
      Time.current > trial_started_at + 28.days
    end
  end

  def inactive_for_more_than_30_days(inactive_subscription)
    if end_date = inactive_subscription.scheduled_for_cancellation_on || inactive_subscription.trial_ends_at
      Time.current > end_date + 30.days
    end
  end

  def upgrade_nylas_account(user)
    account = NylasApi::Admin.new(user.nylas_token)
    if account.upgrade
      user.nylas_account_status = "active"
      user.save!
    end
  end

  def downgrade_nylas_account(user)
    account = NylasApi::Admin.new(user.nylas_token)
    if account.downgrade
      user.nylas_account_status = "inactive"
      user.save!
    end
  end

end
