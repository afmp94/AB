class RegistrationsController < Devise::RegistrationsController

  include UserCreationControllerCallbacksHelper

  def new
    super do
      if params[:survey_token].present?
        survey_result = SurveyResult.find_by(survey_token: params[:survey_token])
        resource.email = survey_result.email
        resource.survey_result_token = survey_result.survey_token
      end

      if params[:referral_code].present?
        referral_code_obj = ReferralCode.find_by(code: params[:referral_code])
        if referral_code_obj.nil? || referral_code_obj.expired_for_account_credit?
          message = "Passed referral code is invalid or expired!"
          redirect_to(new_user_registration_path, alert: message) && return
        else
          resource.referral_code = params[:referral_code]
        end
      end

      if params[:token].present?
        organization_member = OrganizationMember.find_by(
          token: params[:token],
          member_id: nil,
          existing_user: false
        )

        if organization_member.present?
          resource.email = organization_member.email_address
          resource.agent_token = params[:token]
        else
          message = "Token is no longer valid. Please contact support@agentbright.com"
          redirect_to(new_user_registration_path, alert: message) && return
        end

      end

      resource.broker = true if params[:broker] == "true"
    end
  end

  def sign_up_for_agentbright
    build_resource({})
    yield resource if block_given?

    if params[:survey_token].present?
      survey_result = SurveyResult.find_by(survey_token: params[:survey_token])
      resource.email = survey_result.email
      resource.survey_result_token = survey_result.survey_token
    end

    render layout: "application"
  end

  def create
    super do
      analytics.track_user_creation
    end

    return unless resource.save

    after_user_creation_callbacks(current_user)

    flash[:success] = "You are now registered and your 30 day free trial has begun."
  end

  protected

  def after_sign_up_path_for(resource)
    return getting_started_path if resource.is_a?(User)

    super
  end

end
