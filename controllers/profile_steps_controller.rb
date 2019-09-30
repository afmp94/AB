class ProfileStepsController < ApplicationController

  layout "wizard"
  include Wicked::Wizard
  skip_before_action :authenticate_user!, if: :url_has_survey_token
  skip_before_action :redirect_to_assessment_page, if: :skip_redirect_to_assessment_page

  steps :getting_started_video, :import_contacts, :other_information,
        :business_information, :set_goals, :rank_top_contacts, :sync_email,
        :get_mobile_app # :add_first_clients

  def show
    @user        = current_user
    current_step = params[:id]

    case current_step
    when "import_contacts"
      mark_getting_started_video_watched!
      handle_import_contacts_step
      @contact = current_user.contacts.build
      @contact.email_addresses.build
      @contact.phone_numbers.build
    when "set_goals"
      mark_getting_started_video_watched!
      handle_set_goals_step
    when "rank_top_contacts"
      mark_getting_started_video_watched!
      handle_rank_top_contacts_step
    when "sync_email"
      mark_getting_started_video_watched!
      handle_sync_email_step
    # when "add_first_clients"
    #  handle_add_first_clients_step
    when "get_mobile_app"
      path = if downloadable_mobile_app?
               mark_getting_started_video_watched!
               current_user.mark_onboarding_completed!
               mobile_app_path
             else
               profile_steps_path(id: "wicked_finish")
             end
      redirect_to(path) && return
    when "wicked_finish"
      mark_getting_started_video_watched!
      current_user.mark_onboarding_completed!
    end

    @completeness_service = Onboarding::CompleteStepsCheckService.new(current_step, @user, wizard_steps)

    render_wizard
  end

  def update
    @user = current_user
    @user.update_attributes!(user_params)

    remove_profile_image if params[:remove_profile_image] == "true"

    params.delete(:survey_token) if params[:survey_token].present?

    render_wizard @user
  end

  protected

  def user_params
    params.require(:user).permit(
      :id,
      :ab_email_address,
      :address,
      :city,
      :company,
      :company_website,
      :contacts_database_storage,
      :country,
      :email,
      :fax_number,
      :first_name,
      :last_name,
      :mobile_number,
      :name,
      :office_number,
      :onboarding_completed,
      :personal_website,
      :real_estate_experience,
      :state,
      :subscribed,
      :time_zone,
      :zip,
      :monthly_broker_fees_paid,
      :franchise_fee,
      :franchise_fee_per_transaction,
      :commission_split_type,
      :agent_percentage_split,
      :broker_fee_per_transaction,
      :broker_fee_alternative,
      :broker_fee_alternative_split,
      :per_transaction_fee_capped,
      :transaction_fee_cap,
      goals_attributes: [
        :id,
        :annual_transaction_goal,
        :avg_commission_rate,
        :avg_price_in_area,
        :calls_required_wkly,
        :contacts_need_per_month,
        :contacts_to_generate_one_referral,
        :daily_calls_goal,
        :daily_notes_goal,
        :daily_visits_goal,
        :desired_annual_income,
        :est_business_expenses,
        :gross_commission_goal,
        :gross_sales_vol_required,
        :monthly_transaction_goal,
        :note_required_wkly,
        :portion_of_agent_split,
        :qtrly_transaction_goal,
        :referrals_for_one_close,
        :total_weekly_effort,
        :visits_required_wkly,
        :year,
        :agent_percentage_split,
        :broker_fee_alternative,
        :broker_fee_per_transaction,
        :commission_split_type,
        :franchise_fee,
        :franchise_fee_per_transaction,
        :monthly_broker_fees_paid,
        :per_transaction_fee_capped,
        :transaction_fee_cap,
        :broker_fee_alternative_split,
      ]
    )
  end

  private

  def url_has_survey_token
    has_token = false

    if params[:survey_token].present? || current_user.survey_results
      survey_result = SurveyResult.find_by(survey_token: params[:survey_token], imported: false)
      if survey_result&.user&.special_type?
        survey_result.user.make_agentbright_user_and_set_trial_plan!

        service = MailchimpApi::UpdateMemberListService.new(
          Rails.application.secrets.mailchimp[:list][:agentbright_partial_assessment],
          survey_result.user.email,
          Rails.application.secrets.mailchimp[:list][:agentbright_users]
        )
        service.delay.run

        service = MailchimpApi::UpdateMemberListService.new(
          Rails.application.secrets.mailchimp[:list][:agentbright_assessment],
          survey_result.user.email,
          Rails.application.secrets.mailchimp[:list][:agentbright_users]
        )
        service.delay.run

        import_service = SurveyResults::ImportService.new(survey_result.id)
        import_service.delay.process

        sign_in(survey_result.user) if current_user.blank?
        has_token = true
      end
    end

    has_token
  end

  def skip_redirect_to_assessment_page
    params[:survey_token].present?
  end

  def handle_import_contacts_step
    @csv_file = CsvFile.new.csv
    @csv_file.success_action_redirect = create_csv_file_upload_contacts_url
  end

  def handle_set_goals_step
    @goal = current_user.current_goal || current_user.goals.create!
    @commission_carrier = CommissionCarrier.new(@goal.user)
  end

  def handle_rank_top_contacts_step
    if params[:contact_id]
      if @current_contact = current_user.contacts.active.find_by(id: params[:contact_id])
        @current_contact
      else
        set_ungraded_current_contact
      end
    else
      set_ungraded_current_contact
    end

    set_graded_contacts
  end

  def set_ungraded_current_contact
    @current_contact = current_user.contacts.active.random_ungraded_contact params[:dont_rank]
  end

  def set_graded_contacts
    @graded_contacts = current_user.contacts.active.graded.order(graded_at: :desc).limit(10)
  end

  def handle_sync_email_step
    @authorization = current_user.authorizations.new
    if current_user.has_nylas_token?
      @nylas_account = NylasApi::Account.new(current_user.nylas_token)
    end
  end

  # not used
  # def handle_add_first_clients_step
  #   @first_clients = current_user.contacts.limit(5)
  # end

  def mark_getting_started_video_watched!
    @user.update!(getting_started_video_watched: true) unless @user.getting_started_video_watched?
  end

end
