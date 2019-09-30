module Reminders

  class ImportantDateReminderService

    attr_reader :user, :date, :types

    def initialize(user, date, types=[])
      @user  = user
      @date  = date
      @types = types
    end

    def process
      contact_ids = user.contacts.active.pluck(:id)
      ImportantDate.for_daily_recap(contact_ids, date, types).includes(:contact)
    end

  end

end
