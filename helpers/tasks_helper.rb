module TasksHelper

  def link_to_associated_record(task)
    type = task.taskable_type
    id = task.taskable_id
    if type && id
      record = task.related_to
      if type == "Contact"
        link_to("#{record.full_name} (#{type})", record)
      elsif type == "Lead"
        link_to("#{record.name} (#{type})", record)
      elsif type == "Client"
        link_to("#{record.name} (#{type})", record)
      else
        link_to("#{type} ##{id}", record)
      end
    end
  end

  def show_assigned_to(task)
    user = task.assigned_to
    if user
      user.name
    end
  end

  def show_taskable(task)
    return "" if task.taskable.blank?
    taskable = task.taskable
    taskable_type = task.taskable_type
    if taskable_type == "Contact"
      "#{taskable.full_name} (#{taskable_type})"
    elsif taskable_type == "Lead"
      if taskable.status == 0
        "#{taskable.name} (Lead)"
      else
        "#{taskable.name} (Client)"
      end
    end
  end

  def show_taskable_mailer(task)
    return "" if task.taskable.blank?

    taskable = task.taskable
    taskable_type = task.taskable_type

    case taskable_type
    when "Contact"
      "#{taskable.full_name} (#{taskable_type})"
    when "Lead"
      taskable.name
    end
  end

  def show_taskable_link(task)
    return "" if task.taskable.blank?
    taskable = task.taskable
    taskable_type = task.taskable_type
    if taskable_type == "Contact"
      link_to "#{taskable.full_name} (#{taskable_type})", taskable, class: "small-meta fwb"
    elsif taskable_type == "Lead"
      if taskable.status == 0
        link_to "#{taskable.name} (Lead)", taskable, class: "small-meta fwb"
      else
        link_to "#{taskable.name} (Client)", taskable, class: "small-meta fwb"
      end
    end
  end

  def todo_completed_class(task)
    if task.completed
      "completed"
    end
  end

  def todo_overdue_class(task)
    if task.is_overdue?
      "overdue"
    end
  end

  def user_and_teammate_array(current_user)
    User.where(id: current_user.team_member_ids)
  end

  def display_number_of_tasks_create_and_completed_since_yesterday(lead)
    if lead.number_of_tasks_created_since_yesterday > 0
      created = "#{pluralize(lead.number_of_tasks_created_since_yesterday, 'task was', plural: 'tasks were')} added"
    end
    if lead.number_of_tasks_completed_since_yesterday > 0
      completed = "#{pluralize(lead.number_of_tasks_completed_since_yesterday, 'task was', plural: 'tasks were')} completed"
    end
    "#{[created, completed].map(&:presence).compact.join(' and ')}:"
  end

  def display_number_of_tasks_create_and_completed_since_last_week(lead)
    if lead.number_of_tasks_created_since_last_week > 0
      created = "#{pluralize(lead.number_of_tasks_created_since_last_week, 'task was', plural: 'tasks were')} added"
    end
    if lead.number_of_tasks_completed_since_last_week > 0
      completed = "#{pluralize(lead.number_of_tasks_completed_since_last_week, 'task was', plural: 'tasks were')} completed"
    end
    "#{[created, completed].map(&:presence).compact.join(' and ')}:"
  end

  def task_pill_contents(task)
    attributes = []
    attributes << task.assigned_to_name if task.assigned_to_name.present?
    attributes << short_date(task.due_date_at) if task.due_date_at.present?
    attributes.join(" · ")
  end

  def from_page_param(from_page=nil)
    from_page || params[:from_page].presence || "#{controller_name}-#{action_name}"
  end

end
