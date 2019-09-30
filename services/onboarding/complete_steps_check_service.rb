module Onboarding

  class CompleteStepsCheckService

    attr_reader :current_page, :user, :ordered_steps

    def initialize(current_step, user, ordered_steps)
      @current_page  = current_step
      @user          = user.reload
      @ordered_steps = ordered_steps || default_steps
    end

    def getting_started_video_step_completed?
      user.getting_started_video_watched?
    end

    def import_contacts_step_completed?
      user.contacts.count > 5
    end

    def other_information_step_completed?
      user.profile_image.present?
    end

    def business_information_step_completed?
      user.mobile_number.present?
    end

    def set_goals_step_completed?
      user.goals_entered?
    end

    def rank_top_contacts_step_completed?
      user.contacts_with_grade_count >= User::MIN_CONTACTS_FOR_INITIAL_SETUP
    end

    def sync_email_step_completed?
      user.has_nylas_token?
    end

    def add_first_clients_step_completed?
      # some logic
    end

    private

    def default_steps
      %i(
        add_first_clients
        business_information
        getting_started_video
        import_contacts
        other_information,
        rank_top_contacts
        set_goals
        sync_email
      )
    end

  end

end
