class AssessmentsController < ApplicationController

  layout "landing_page"

  skip_before_action :authenticate_user!, :redirect_if_subscription_inactive

  before_action :set_survey_result_and_user, only: [:agent_assessment_payment, :purchase_assessment]

  helper_method :resource_name, :resource, :devise_mapping, :resource_class

  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def resource_class
    User
  end

  def agent_assessment
    set_special_code_variables

    @survey_result = current_user&.survey_result || SurveyResult.new

    if current_user&.survey_result.present?
      redirect_to agent_assessment_payment_path(survey_token: @survey_result.survey_token)
    elsif free_assessment?
      @survey_result.payment_status = 3
    end
  end

  def agent_assessment_payment
    if @survey_result.nil?
      redirect_to assessment_path
    elsif allowed_to_see_survey_result?
      flash[:error] = "You already have ordered a full report!" if @survey_result.ordered_full_report?
      redirect_to public_survey_full_view_report_path(@survey_result.survey_token)
    else
      retrieve_stripe_customer

      build_required_report_objects
    end
  end

  def sample_report
    redirect_to(
      public_survey_full_view_report_path(
        SurveyResult.find_by(email: "frank0@example.com").survey_token
      ) || assessment_path
    )
  end

  def purchase_assessment
    build_required_report_objects

    @user.password_change_notification_required = false # Don't send password change notification

    if @user.save_with_payment(user_params, params["stripe_token"])
      @survey_result.ordered_full_report!

      UserMailer.delay.send_assessment_receipt(@user, @survey_result)
      message = "Thank you for ordering a full report!"

      redirect_to public_survey_full_view_report_path(@survey_result.survey_token),
                  notice: message
    else
      retrieve_stripe_customer

      flash.now[:error] = "There were some errors. Please kindly check those errors..."
      render :agent_assessment_payment
    end
  end

  def check_email_availability
    vip_user = false
    user     = nil

    if SurveyResult::VIP_LIST.include?(params[:email_address])
      vip_user = true
    else
      user = User.find_by(email: params[:email_address])
    end

    if user.present?
      survey_result = SurveyResult.find_by(email: user.email)
      app_login =  survey_result&.ordered_full_report? || user&.stripe_customer_id.present?

      render json: { email_availability: false, app_login: app_login, vip_user: vip_user }
    else
      render json: { email_availability: true, app_login: app_login, vip_user: vip_user }
    end
  end

  def email_login
    survey_result = SurveyResult.where(email: params[:email], payment_status: 3).last

    if survey_result.nil?
      survey_result = SurveyResult.find_by(email: params[:email], ordered_full_report: false)
    end

    if survey_result.present?
      redirect_to agent_assessment_payment_path(survey_token: survey_result.survey_token)
    else
      flash[:error] = "Email not found"
      redirect_to assessment_login_path
    end
  end

  def user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      :address,
      :city,
      :state,
      :zip,
      :password,
      :password_confirmation,
      :stripe_customer_id
    )
  end

  def build_required_report_objects
    @branding_service            = SurveyResults::BrandingService.new(@survey_result)
    @database_service            = SurveyResults::DatabaseService.new(@survey_result)
    @relationship_service        = SurveyResults::RelationshipMarketingService.new(@survey_result)
    @marketing_service           = SurveyResults::MassMarketingService.new(@survey_result)
    @lead_response_service       = SurveyResults::LeadResponseService.new(@survey_result)
    @prospect_conversion_service = SurveyResults::ProspectConversionService.new(@survey_result)
    @agent_service               = SurveyResults::AgentService.new(@survey_result)
    @pipeline_service            = SurveyResults::PipelineService.new(@survey_result)
  end

  private

  def set_survey_result_and_user
    if current_user.nil?
      @survey_result = SurveyResult.find_by(survey_token: params[:survey_token])
      @user = set_or_create_user
    else
      @survey_result = current_user.survey_result
      @user = current_user
    end
  end

  def set_or_create_user
    if @survey_result&.user
      @survey_result&.user
    elsif params[:user]
      create_new_user_for_survey_result
    elsif @survey_result.nil?
      nil
    else
      User.new(
        email: @survey_result.email,
        first_name: @survey_result.first_name,
        last_name: @survey_result.last_name,
        special_type: true
      )
    end
  end

  def create_new_user_for_survey_result
    user = User.new(
      email: @survey_result.email,
      first_name: @survey_result.first_name,
      last_name: @survey_result.last_name,
      special_type: true,
      password: params[:user][:password],
      password_confirmation: params[:user][:password_confirmation]
    )

    user.skip_confirmation!

    if user.save!
      @survey_result.update(user_id: user.id)
    end

    user
  end

  def allowed_to_see_survey_result?
    @survey_result.free? || @survey_result.ordered_full_report? ||
      (@user&.has_active_subscription? && !@user&.in_trial_without_card?)
  end

  def free_assessment?
    (params[:free] == "true") || access_code_is_not_expired?
  end

  def set_special_code_variables
    @broker_code = params[:broker_code]
    @office_code = params[:office_code]
    @email       = params[:email]
    @access_code = survey_access_code

    inform_user_if_access_code_is_invalid_or_expired if @access_code.present?
  end

  def access_code_is_not_expired?
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

    redirect_to(assessment_path) && return if flash[:error].present?
  end

  def retrieve_stripe_customer
    if stripe_customer_id = @user&.stripe_customer_id
      @stripe_customer = Stripe::Customer.retrieve(stripe_customer_id)
    end
  end

  def survey_access_code
    # Need to keep these both params.
    params[:access_code].presence || params[:referral_code]
  end

end
