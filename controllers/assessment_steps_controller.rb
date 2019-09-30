class AssessmentStepsController < ApplicationController

  layout "landing_page"
  include Wicked::Wizard
  include AssessmentParams

  skip_before_action :authenticate_user!, :redirect_if_subscription_inactive
  before_action :redirect_to_survey_report, only: :show

  steps :landing_page, :branding, :contacts,
        :personal_marketing, :mass_marketing, :lead_generation, :service_clients,
        :goal_setting, :current_year_progress, :info, :finish_survey

  def show
    set_special_code_variables

    inform_user_if_access_code_is_invalid_or_expired if @access_code.present?

    @user = current_user
    current_step = step_id || "landing_page"
    @survey_result = survey_result || SurveyResult.new
    render_step(current_step)
  end

  def update
    set_special_code_variables

    @next_step = step_id
    @user = current_user

    if params[:source].present? && params[:source] == "landing"
      Rails.logger.info "Source 'Landing' present. Creating @survey_result"
      @survey_result = survey_result ||
                       SurveyResult.new(
                         broker_code: @broker_code,
                         access_code: @access_code,
                         office_code: @office_code
                       )
    else
      @survey_result = survey_result || create_survey_result
      @survey_result.update_attributes!(assessment_params)
    end

    service_attributes
    render_or_redirect(@next_step)
  end

  private

  def service_attributes
    case @next_step
    when "contacts"
      @branding_service = SurveyResults::BrandingService.new(@survey_result)
    when "personal_marketing"
      @database_service = SurveyResults::DatabaseService.new(@survey_result)
    when "mass_marketing"
      @relationship_service = SurveyResults::RelationshipMarketingService.new(@survey_result)
    when "lead_generation"
      @marketing_service = SurveyResults::MassMarketingService.new(@survey_result)
    when "service_clients"
      @lead_response_service = SurveyResults::LeadResponseService.new(@survey_result)
      @prospect_conversion_service = SurveyResults::ProspectConversionService.new(@survey_result)
      @total_score_in_percentage = (
        @lead_response_service.total_score_in_percentage +
        @prospect_conversion_service.total_score_in_percentage
      )/2
    when "goal_setting"
      @agent_service = SurveyResults::AgentService.new(@survey_result)
    when "current_year_progress"
      @pipeline_service = SurveyResults::PipelineService.new(@survey_result)
    end
  end

  def render_or_redirect(step)
    if step == "finish_survey"
      assessment = survey_result
      assessment.mark_completed!
      session[:survey_result_id] = nil

      if assessment.free?
        redirect_to public_survey_full_view_report_path(assessment.survey_token)
      else
        redirect_to agent_assessment_payment_path(survey_token: assessment.survey_token)
      end
    else
      render_step(step)
    end
  end

  def step_id
    assessment_step = if ["Next", "Get My Results"].include?(params[:commit])
                        params[:next_step_id]
                      else
                        params[:last_step_id]
                      end
    assessment_step
  end

  def survey_result
    if current_user.present?
      current_user&.survey_result || SurveyResult.new(user_id: current_user.id)
    else
      SurveyResult.find_by(id: session[:survey_result_id])
    end
  end

  def create_survey_result
    survey_result = if current_user.present?
                      SurveyResult.create(user_id: current_user.id)
                    elsif valid_access_code
                      SurveyResult.create(assessment_params.merge(payment_status: 3))
                    else
                      SurveyResult.create(assessment_params)
                    end

    session[:survey_result_id] = survey_result.id
    survey_result
  end

  def allowed_to_see_survey_result?
    survey_result.free? || survey_result.ordered_full_report? ||
      (current_user&.has_active_subscription? && !current_user&.in_trial_without_card?)
  end

  def redirect_to_survey_report
    if survey_result.present? && allowed_to_see_survey_result? &&
       survey_result&.survey_token.present? && survey_result.completed
      redirect_to public_survey_full_view_report_path(survey_result.survey_token)
    end
  end

  def set_special_code_variables
    @broker_code = params[:broker_code]
    @office_code = params[:office_code]
    @email       = params[:email]
    @access_code = survey_access_code
  end

  def valid_access_code
    referral_code = ReferralCode.find_by(code: survey_access_code)
    referral_code.present? && !referral_code.expired?
  end

  def inform_user_if_access_code_is_invalid_or_expired
    referral_code = ReferralCode.find_by(code: survey_access_code)

    if referral_code.nil?
      flash[:error] = "Access code is not valid"
    elsif referral_code.expired?
      flash[:error] = "Free offer is expired but you can continue with complimentary one"
    end
  end

  def survey_access_code
    params[:access_code].presence || params[:referral_code].presence ||
      if params[:survey_result].present?
        params[:survey_result][:access_code]
      end
  end

  def assessment_params
    params.require(:survey_result).permit(params_list)
  end

end
