module AssessmentsHelper

  def path_for_agentbright_image(survey_result)
    if survey_result.user&.special_type?
      profile_steps_path(survey_token: survey_result.survey_token)
    elsif survey_result.user.nil?
      new_user_registration_path(survey_token: survey_result.survey_token)
    else
      new_user_session_path
    end
  end

  def branding_result(survey_result)
    workload = survey_result.workload
    results = if workload == "<p>More than 60 hours per week. You may be working too hard!</p>"
              elsif workload == "<p>35 to 59 hours per week. You're in range!</p>"
              else
                "<p>Looks like you are working part-time!</p>"
              end

    results
  end

  def contacts_result(total_score_in_percentage)
    case total_score_in_percentage
    when 80..100
      result = "<p>You have your fundamentals in place!</p>"
    when 60..79
      result = "<p>You are on track, just a few things to update!</p>"
    when 0..59
      result = "<p>We suggest to update your business fundamentals!</p>"
    end
    result
  end

  def personal_marketing(total_score_in_percentage)
    case total_score_in_percentage
    when 80..100
      result = "<p>Great work! You have a good database and you manage it well.</p>"
    when 60..79
      result = "<p>Some work is needed. This can significantly improve your real estate business.</p>"
    when 0..59
      result = "<p>Building and managing is crucial to your success. Make this a priority.</p>"
    end
    result
  end

  def mass_marketing(total_score_in_percentage)
    case total_score_in_percentage
    when 80..100
      result = "<p>Great work! You are tops in networking!</p>"
    when 60..79
      result = "<p>You are leaving 'easy money' on the table." +
               " Be sure to setup and/or use a system to keep in touch with your relationships.</p>"
    when 0..59
      result = "<p>Networking with your relationships" +
               " is core to being successful. In terms of time and money, setup and/or use a system" +
               " to keep in touch with your relationships.</p>"
    end
    result
  end

  def lead_generation(total_score_in_percentage)
    case total_score_in_percentage
    when 80..100
      result = "<p>Great work! You are tops in marketing yourself and your business.</p>"
    when 60..79
      result = "<p>You can up your game! Be sure to get balance in marketing your message.</p>"
    when 0..59
      result = "<p>Oops! You are leaving easy money on the table." +
               " Focus on getting a Lead management system in place.</p>"
    end
    result
  end

  def service_clients(total_score_in_percentage)
    case total_score_in_percentage
    when 80..100
      result = "<p>Great work! Your lead pipeline is well managed.</p>"
    when 60..79
      result = "<p>You are leaving easy money on the table." +
               " Responding to a lead within 5 minutes increases your chances of converting the client by 72%." +
               " Be sure to review how you are managing your leads.</p>"
    when 0..59
      result = "<p>If you are great, no one knows! Invest in getting your marketing systems setup.</p>"
    end
    result
  end

  def goal_setting(total_score_in_percentage)
    case total_score_in_percentage
    when 80..100
      result = "<p>Wow! Superstar! Your sales pipeline is well managed.</p>"
    when 60..79
      result = "<p>Servicing and pipeline management is all about planning, " +
               "measuring and communicating to satisfy clients! We have some recommendations for you.</p>"
    when 0..59
      result = "<p>Oops!  You worked so hard to get the Lead, " +
               "take some time to improve managing your clients and their expectations.</p>"
    end
    result
  end

  def render_quick_results(previous_step:, data_percent: nil, &block)
    render(
      partial: "assessment_steps/quick_results",
      locals: {
        previous_step: previous_step,
        data_percent: data_percent,
        block: block
      }
    )
  end

  def sidebar_class(active_step, this_step)
    if this_step == active_step
      "active"
    elsif this_step < active_step
      "completed"
    end
  end

  def reaction_attribute(step)
    steps = [
      "info",
      "branding",
      "contacts",
      "personal_marketing",
      "mass_marketing",
      "lead_generation",
      "service_clients",
      "goal_setting",
      "current_year_progress",
      "finish_survey"
    ]

    step_index = steps.index(step)
    steps[step_index-1]
  end

  def render_title_message(icon_class: nil, header: nil, content: nil, &block)
    render(
      partial: "assessment_steps/title_message",
      locals: {
        icon_class: icon_class,
        header: header,
        content: content,
        block: block
      }
    )
  end

end
