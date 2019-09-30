require "activerecord/session_store"

class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception

  before_action :set_device_type
  before_action :set_layout_carrier
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  around_action :user_time_zone, if: :current_user
  before_action :set_honeybadger_context
  before_action :set_paper_trail_whodunnit

  before_action :redirect_to_assessment_page, if: :current_user
  before_action :redirect_if_subscription_inactive, if: :current_user
  before_action :check_rack_mini_profiler

  add_flash_types :success, :info, :warning, :danger

  include PublicActivity::StoreController
  include SuperadminHelper
  include GoogleHelper
  helper DatetimeFormattingHelper
  helper DashboardHelper

  respond_to :html, :js, if: :devise_controller?

  def analytics
    @analytics ||= Analytics.new(current_user, google_analytics_client_id)
  end

  def google_analytics_client_id
    google_analytics_cookie.gsub(/^GA\d\.\d\./, "")
  end

  def google_analytics_cookie
    cookies["_ga"] || ""
  end

  def redirect_if_subscription_inactive
    if current_user && !current_user_has_active_subscription?
      redirect_to billing_url
    end
  end

  def redirect_to_assessment_page
    if current_user.special_type?
      survey_result = SurveyResult.find_by(user_id: current_user.id)
      if current_user.stripe_customer_id.present?
        redirect_to public_survey_full_view_report_path(survey_result.survey_token)
      elsif controller_name != "assessments" && action_name != "agent_assessment_payment"
        redirect_to agent_assessment_payment_path(survey_token: survey_result.survey_token)
      end
    end
  end

  protected

  def check_rack_mini_profiler
    if params[:rmp]
      Rack::MiniProfiler.authorize_request
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(
      :sign_up,
      keys: %i(first_name last_name username survey_result_token referral_code broker agent_token)
    )
  end

  def must_be_super_admin
    unless super_admin_signed_in?
      flash[:error] = "You do not have permission to view that page."
      redirect_to root_url
    end
  end

  def must_be_subscription_owner
    unless current_user_is_subscription_owner?
      deny_access("You must be the owner of this subscription")
    end
  end

  def current_user_is_subscription_owner?
    current_user_has_active_subscription? &&
      current_user.subscription.owner?(current_user)
  end
  helper_method :current_user_is_subscription_owner?

  def current_user_has_active_subscription?
    current_user&.has_active_subscription?
  end
  helper_method :current_user_has_active_subscription?

  def masquerading?
    session[:admin_id].present?
  end
  helper_method :masquerading?

  def current_team
    current_user.team_group
  end
  helper_method :current_team_group

  def current_user_has_access_to?(feature)
    current_user&.has_access_to?(feature)
  end

  def back_location_path(fallback_url:)
    @_back_url || fallback_url
  end
  helper_method :back_location_path

  def forced_form_for_mobile_app?
    params[:forced_form_for_mobile_app] == "true"
  end
  helper_method :forced_form_for_mobile_app?

  private

  def user_time_zone(&block)
    Time.use_zone(current_user.time_zone, &block)
  end

  def set_device_type
    request.variant = if ios_app?
                        :ios
                      elsif android_app?
                        :android
                      elsif browser.device.mobile? || browser.device.tablet?
                        :phone
                      end
  end

  def mobile_app?
    ios_app? || android_app?
  end

  def ios_app?
    browser.ua.match?(Rails.application.secrets.ios_user_agent)
  end

  def android_app?
    browser.ua.match?(Rails.application.secrets.android_user_agent)
  end

  def ios_browser?
    browser.device.iphone?
  end

  def android_browser?
    browser.platform.android?
  end

  def dont_use_json?
    request.path.include?(Devise.mappings[:user].fullpath) || current_user.present?
  end

  def set_layout_carrier
    @layout_carrier = LayoutCarrier.new
  end

  def set_honeybadger_context
    hash = {
      uuid: request.uuid,
      papertrail_url: "https://papertrailapp.com/events?time=#{Time.now.gmtime.to_i}"
    }
    if current_user
      hash.merge!(
        user_id: current_user.id,
        user_email: current_user.email,
        user_name: current_user.name
      )
    end
    Honeybadger.context hash
  end

  def deny_access(message)
    flash[:danger] = message
    redirect_back(fallback_location: root_path)
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def set_referring_page(page=nil)
    session[:referring_page] = page || request.referer
  end
  helper_method :set_referring_page

  def set_referring_page_with_backup(backup)
    session[:referring_page] = request.referer || backup
  end
  helper_method :set_referring_page_with_backup

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def called_from_index_page?(controller=controller_name)
    request.referer =~ %r{/#{controller}$}
  end
  helper_method :called_from_index_page?

  def called_from_landing_page?(controller=controller_name)
    request.referer =~ %r{/#{controller}/\w+}
  end
  helper_method :called_from_landing_page?

  def current_page=(page)
    p = page.to_i
    @current_page = session[:"#controller_name}_current_page"] = (p.zero? ? 1 : p)
  end

  def current_page
    page = params[:page] || session[:"#controller_name}_current_page"] || 1
    @current_page = page.to_i
  end

  def after_sign_in_path_for(resource, location=nil)
    location || request.env["omniauth.origin"] || stored_location_for(resource) || handle_after_sign_in_path
  end

  def handle_after_sign_in_path
    if current_user.special_type?
      handle_assessment_path
    elsif current_user && !current_user_has_active_subscription?
      billing_url
    else
      root_path
    end
  end

  def handle_assessment_path
    survey_result = SurveyResult.find_by(user_id: current_user.id)

    if current_user.stripe_customer_id.present?
      public_survey_full_view_report_path(survey_result.survey_token)
    else
      agent_assessment_payment_path(survey_token: survey_result.survey_token)
    end
  end

  def remove_profile_image
    current_user.profile_image&.destroy
  end

  def check_broker_permission
    unless current_user.broker?
      flash[:warning] = "You don't have permission to access this page!"
      redirect_to root_path
    end
  end

  def mobile_app_path
    if browser.device.iphone?
      get_ios_app_path
    elsif browser.platform.android?
      get_android_app_path
    end
  end
  helper_method :mobile_app_path

  def downloadable_mobile_app?
    browser.device.iphone? || browser.platform.android?
  end
  helper_method :downloadable_mobile_app?

  def current_subdomain
    request&.subdomain
  end
  helper_method :current_subdomain

end
