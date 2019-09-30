module Superadmin::LeadEmailsHelper

  def display_email_contents(email)
    content_to_display = if email.html.present?
                           email.html.html_safe
                         elsif email.text.present?
                           simple_format email.text
                         else
                           " "
                         end
    content_to_display
  end

  def lead_email_row_class(lead_email)
    state = lead_email.importing_state
    created_at = lead_email.created_at
    case state
    when "imported"
      "positive"
    when "failed"
      "error"
    when "parsing_error"
      "error"
    when "no_parser_found"
      "warning"
    when "processing"
      if created_at <= Time.zone.now - 30.minutes
        "error"
      else
        "warning"
      end
    end
  end

  def stats_highlight(count, color)
    if count > 0
      color&.to_s
    end
  end

  def time_to_process_lead_email(lead_email)
    received_at = lead_email.date
    lead_created = lead_email&.lead&.created_at

    if received_at && lead_created
      distance_of_time_in_words(received_at, lead_created)
    end
  end

end
