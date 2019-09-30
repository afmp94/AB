class ActionPlanStepExecuter

  def process
    ActionPlanMembership.all.ready_to_execute.each do |action_plan_membership|
      if lead_status_changed?(action_plan_membership)
        cancel_membership(action_plan_membership)
      else
        execute_step(action_plan_membership)
      end
    end
  end

  def execute_step(action_plan_membership)
    current_step = action_plan_membership.next_step
    contact = action_plan_membership.contact
    user = contact.user

    if current_step.require_approval
      action_plan_membership.update_attributes(state: "waiting_for_approval")
    else
      send_email(user, contact, current_step.email_template, action_plan_membership)

      update_action_plan_membership_fields(current_step, action_plan_membership)
    end
  end

  def send_email(user, contact, email_template, action_plan_membership)
    response = NylasApi::EmailSender.new(user).send(
      name: contact.name,
      email: contact.primary_email_address.email,
      subject: email_template.subject,
      body: dynamic_message_body(email_template.message_body, contact, action_plan_membership)
    )

    create_email_message(response, user, action_plan_membership.id)
  end

  def update_action_plan_membership_fields(current_step, action_plan_membership)
    next_step = current_step.next

    if next_step
      action_plan_membership.update_attributes(
        last_step_id: current_step.id,
        last_step_at: Time.current,
        next_step_id: next_step.try(:id),
        next_step_at: datetime_of_next_step(next_step)
      )
    else
      action_plan_membership.update_attributes(state: "completed")
    end
  end

  private

  def dynamic_message_body(message, contact, action_plan_membership)
    ActionPlanMessageConstructor.new(message, contact, action_plan_membership).construct
  end

  def create_email_message(response, user, action_plan_membership_id)
    user.email_messages.create(email_message_params(response, action_plan_membership_id))
  end

  def parse_emails(to_array)
    to_array.map(&:email).map(&:downcase)
  end

  def email_message_params(response, action_plan_membership_id)
    {
      message_id: response.id,
      thread_id: response.thread_id,
      subject: response.subject,
      from_email: response.from[0].email,
      to: response.to[0]&.email,
      cc: response.cc[0]&.email,
      bcc: response.bcc[0]&.email,
      received_at: response.date,
      snippet: response.snippet,
      body: response.body
    }.merge(associated_params(response, action_plan_membership_id))
  end

  def associated_params(response, action_plan_membership_id)
    {
      unread: response.unread,
      account: response.account_id,
      from_name: response.from[0]&.name,
      to_email_addresses: parse_emails(response.to),
      account_id: response.account_id,
      action_plan_membership_id: action_plan_membership_id
    }
  end

  def cancel_membership(action_plan_membership)
    action_plan_membership.update_attributes(state: :cancelled, end_action_plan: true)
  end

  def lead_status_changed?(action_plan_membership)
    if action_plan_membership.lead.present?
      action_plan_membership.lead.status != action_plan_membership.lead_status_when_initiated
    else
      false
    end
  end

  def datetime_of_next_step(next_step)
    execute_at = Time.zone.parse(next_step.send_time.to_s) || Time.current

    if next_step.delay_in_days.present?
      execute_at = execute_at + next_step.delay_in_days.to_i.days
    end
    execute_at
  end

end
