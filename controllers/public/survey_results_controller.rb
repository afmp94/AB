class Public::SurveyResultsController < ApplicationController

  include AssessmentParams
  skip_before_action :authenticate_user!, :redirect_to_assessment_page, :redirect_if_subscription_inactive
  before_action :set_survey_result, only: [:agent_assessment, :load_agent_assessment, :update]
  layout "landing_page"

  def sample_broker_report
    @broker_code = params[:broker_code] || "Randall Group"
    @office_code = params[:office_code] || "Essex"

    @summary = BrokerReport::SummaryService.new(@broker_code, @office_code)
    @agent_metrics = BrokerReport::AgentMetricsService.wrap(@broker_code, @office_code)
    @statistics = BrokerReport::AgentProfile::StatisticsService.wrap(@broker_code, @office_code)
    @business_analysis_service = BrokerReport::BusinessDevelopment::AnalysisService.wrap(@broker_code, @office_code)
    @goals_summary_headers = BrokerReport::FinancialSummary::HeaderService.wrap(@broker_code, @office_code)
    @agent_experiences = BrokerReport::FinancialSummary::AgentExperienceService.wrap(@broker_code, @office_code)
    @all_agents = BrokerReport::ComparativeFinancialStats::AllAgentsService.wrap(@broker_code, @office_code)
    @full_time_agents = BrokerReport::ComparativeFinancialStats::FullTimeAgentsService.wrap(@broker_code, @office_code)
    @part_time_agents = BrokerReport::ComparativeFinancialStats::PartTimeAgentsService.wrap(@broker_code, @office_code)

    render "survey_results/sample_broker_report"
  end

  def create
    @survey_result = SurveyResult.new(survey_result_params)
    @survey_result.user_id = current_user.id if current_user

    if @survey_result.save
      token = @survey_result.survey_token

      add_new_user_to_mailchimp_list

      if @survey_result.free?
        redirect_to public_survey_full_view_report_path(token)
      else
        redirect_to agent_assessment_payment_path(survey_token: token)
      end
    else
      flash.now[:danger] = "Please check your entry and try again."
      render "assessments/agent_assessment"
    end
  end

  def agent_assessment
    @user = @survey_result.user

    if allowed_to_see_survey_result?
      render "survey_results/loading_indicator"
    else
      flash[:error] = "You haven't ordered full report page. Please order first!"
      redirect_to agent_assessment_payment_path(survey_token: @survey_result.survey_token)
    end
  end

  def load_agent_assessment
    @user = @survey_result.user

    @branding_service = SurveyResults::BrandingService.new(@survey_result)
    @database_service = SurveyResults::DatabaseService.new(@survey_result)
    @relationship_service = SurveyResults::RelationshipMarketingService.new(@survey_result)
    @marketing_service = SurveyResults::MassMarketingService.new(@survey_result)
    @lead_response_service = SurveyResults::LeadResponseService.new(@survey_result)
    @prospect_conversion_service = SurveyResults::ProspectConversionService.new(@survey_result)
    @agent_service = SurveyResults::AgentService.new(@survey_result)
    @pipeline_service = SurveyResults::PipelineService.new(@survey_result)

    render "survey_results/agent_assessment", layout: false
  end

  def update
    if @survey_result.update(survey_result_params)
      render "survey_results/update"
    end
  end

  def show
    @survey_result = SurveyResult.find_by(survey_token: params[:id])
    render "survey_results/show"
  end

  private

  def set_survey_result
    @survey_result = SurveyResult.find_by(survey_token: params[:survey_token])
  end

  def add_new_user_to_mailchimp_list
    if @survey_result.user.present?
      service = MailchimpApi::UpdateMemberListService.new(
        Rails.application.secrets.mailchimp[:list][:potential_customers],
        @survey_result.user.email,
        Rails.application.secrets.mailchimp[:list][:agentbright_assessment]
      )

      service.delay.run
    end
  end

  def allowed_to_see_survey_result?
    @survey_result.free? || (@user.has_active_subscription? && !@user.in_trial_without_card?) ||
      @survey_result.ordered_full_report? || current_user&.super_admin?
  end

  def survey_result_params
    params.require(:survey_result).permit(params_list)
  end

end
