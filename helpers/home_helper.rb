module HomeHelper

  def progress_bar(title, counter, goal)
    goal_was_met = counter >= goal
    goal_percent_completed = (goal_was_met ? 100 : (counter * 100 / goal))
    render(
      partial: "shared/stats/progress_bar",
      locals: {
        counter: counter,
        goal: goal,
        goal_was_met: goal_was_met,
        goal_percent_completed: goal_percent_completed,
        title: title
      }
    )
  end

  def data_for_sorting_complete(active_contacts_count, ungraded_contacts_count)
    if active_contacts_count.zero?
      0
    else
      active_graded_contacts_count = active_contacts_count - ungraded_contacts_count
      sorting_complete_count = active_graded_contacts_count.to_f / active_contacts_count
      number_with_precision(sorting_complete_count * 100.00, precision: 0)
    end
  end

  def set_data_attribute(tasks_list_section)
    if tasks_list_section.present?
      "data-info=#{tasks_list_section}_incomplete_tasks"
    else
      "data-info=tasks_list"
    end
  end

end
