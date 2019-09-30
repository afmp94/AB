module ProfileStepsHelper

  def step_state_class(step)
    completed = @completeness_service.public_send("#{step}_step_completed?")

    if completed
      "completed"
    else
      params[:id] == step ? "active" : ""
    end
  end

  def skip_link_for_rank_top_contacts_step
    skip_path = if current_user.nylas_token.present?
                  profile_steps_path(id: "wicked_finish")
                else
                  next_wizard_path
                end

    link_to("Skip", skip_path, class: "ui button")
  end

  def next_link_for_rank_top_contacts_step(showable_link=true)
    skip_path = if current_user.nylas_token.present?
                  profile_steps_path(id: "wicked_finish")
                else
                  next_wizard_path
                end

    link_to(
      "Next",
      skip_path,
      class: "ui primary button reveal-section right floated #{showable_link ? 'is-visible' : ''}",
      "data-behavior": "show-onboarding-next-link"
    )
  end

  def showable_enough_graded_contacts_message?
    @graded_contacts.count >= 5 && !current_user.onboarding_completed?
  end

end
