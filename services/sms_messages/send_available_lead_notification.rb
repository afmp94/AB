class SmsMessages::SendAvailableLeadNotification < Firebase::BasePushNotifier

  private

  def title
    "Unclaimed Lead"
  end

  def body
    return creator_notification if receiver == model.created_by_user

    group_notification
  end

  def creator_notification
    "#{model&.name} was just added."
  end

  def group_notification
    "A new lead #{model&.name} was just added, would you like to claim?"
  end

  def additional_info
    { lead_id: model&.id }
  end

end
