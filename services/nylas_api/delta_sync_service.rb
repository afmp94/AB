class NylasApi::DeltaSyncService

  attr_accessor :user, :account, :beginning_cursor, :ending_cursor,
                :deltas_processed, :deltas_saved

  def initialize(user, account)
    @user    = user
    @account = account
  end

  def sync
    if account.present?
      find_and_set_beginning_cursor_for_fetching_deltas
      set_initial_counter_values_for_logging

      fetch_all_deltas_from_beginning_cursor_and_process

      log_syncing_totals_report
      save_last_ending_cursor
    end
  end

  def latest_cursor
    account.deltas.latest_cursor
  end

  def generate_and_save_beginning_cursor
    @user.update!(last_cursor: latest_cursor)
    latest_cursor
  end

  private

  def find_and_set_beginning_cursor_for_fetching_deltas
    @beginning_cursor = user.last_cursor.presence || generate_and_save_beginning_cursor
  end

  def fetch_all_deltas_from_beginning_cursor_and_process
    log_message "Delta count: #{account.deltas.since(beginning_cursor).count}"
    account.deltas.since(beginning_cursor).each do |delta|
      process_delta(delta)

      set_new_ending_cursor(delta)
    end
  rescue Nylas::APIError => e
    Rails.logger.error "[NYLAS.delta_sync] Error fetching events: #{e}"
    save_last_ending_cursor
    nil
  end

  def process_delta(delta)
    @deltas_processed += 1

    if NylasApi::Deltas::ProcessingService.new(delta).process
      @deltas_saved += 1
    end
  end

  def set_new_ending_cursor(delta)
    @ending_cursor = delta.cursor
  end

  def set_initial_counter_values_for_logging
    @ending_cursor = nil
    @deltas_processed = 0
    @deltas_saved = 0
  end

  def save_last_ending_cursor
    unless ending_cursor.nil?
      @user.update!(last_cursor: ending_cursor)
    end
  end

  def log_message(message)
    Rails.logger.info "[NYLAS.delta_sync] #{message}"
  end

  def log_syncing_totals_report
    log_message "Email account: #{user.nylas_connected_email_account}"
    log_message "Starting cursor: #{beginning_cursor}, Ending cursor: #{ending_cursor}"
    log_message(
      "Total deltas: #{deltas_processed}, "\
      "Saved: #{deltas_saved}"
    )
  end

end
