module EmailsHelper

  def email_list_datetime(datetime)
    now = Time.current
    if datetime > now
      "in #{time_ago_in_words(datetime)}"
    elsif datetime > now.beginning_of_day
      datetime.strftime("%I:%M%p").to_s
    elsif datetime > now.beginning_of_day - 5.days
      datetime.strftime("%a %I:%M%p").to_s
    elsif datetime > now.beginning_of_year
      datetime.strftime("%b %e").to_s
    else
      datetime.strftime("%b %e, %Y").to_s
    end
  end

  def get_first_name(name)
    if name.present?
      name.split.first
    end
  end

  def list_participants(object, attribute)
    names = []

    if attribute == "to"
      participants = []
      participants << object.send(attribute)
      participants << object.send("cc")
      participants.flatten!
    else
      participants = object.send(attribute)
    end

    participants.each do |participant|
      name  = participant.name
      email = participant.email
      if [current_user.nylas_connected_email_account, current_user.email].include?(email)
        names << "Me"
      elsif name.present?
        names << (participants.size == 1 ? name : get_first_name(name))
      else
        names << email.split("@").first
      end
    end

    names.join(", ")
  end

  def participant_name_or_email(participant)
    name = participant["name"]
    email = participant["email"]
    if email == current_user.nylas_connected_email_account
      "Me"
    elsif name.present?
      get_first_name(name)
    else
      email.split("@").first
    end
  end

  def thread_is_unread?(thread)
    thread.tags.detect { |tag| tag["name"] == "unread" }
  end

  def message_is_unread?(message)
    if message.respond_to? :unread
      message.unread == true
    end
  end

  def thread_unread_class(thread)
    if thread_is_unread?(thread)
      "unread"
    end
  end

  def message_unread_class(message)
    if message_is_unread?(message)
      "unread"
    end
  end

  def most_recent_message_index
    1
  end

  def message_collapse_header(message_index, message)
    unless need_message_collapse?(message_index, message)
      "active"
    end
  end

  def message_collapse_body(message_index, message)
    unless need_message_collapse?(message_index, message)
      "active"
    end
  end

  def reverse_message_order(inbox_object)
    array = []
    inbox_object.each do |object|
      array << object
    end
    reversed = array.reverse
    reversed
  end

  def protected_nylas_email_account?(current_user)
    [
      "john.smith.agentbright@gmail.com",
      "jane.jones.agentbright@gmail.com",
      "sam.solo.agentbright@gmail.com"
    ].include?(current_user.nylas_connected_email_account)
  end

  private

  def need_message_collapse?(message_index, message)
    message_index != most_recent_message_index && !message_is_unread?(message)
  end

end
