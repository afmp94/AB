class HomeController < ApplicationController

  include RecentActivities

  before_action :set_contacts_csv_upload_status, only: [:index, :dashboard]

  def apple_app_site_association
    association_json = File.read(Rails.public_path + "apple-app-site-association")
    render json: association_json, content_type: "application/pkcs7-mime"
  end

  def getting_started
    @user = current_user
    @completeness_service = Onboarding::CompleteStepsCheckService.new(current_page, @user, nil)
    render layout: "wizard"
  end

  def index
    if current_user.onboarding_completed?
      current_user.create_goal! if current_user.goals.blank?

      @dashboard_presenter         = Home::DashboardPresenter.new(current_user)
      @stats_service               = Clients::PipelineStatsService.new(current_user)
      @activities, @activities_url = team_activities(current_user, params[:activity_feed_page])

      set_referring_page(clients_path)
      set_contacts_csv_upload_status

      render :dashboard
    else
      redirect_to getting_started_path
    end
  end

  def dashboard
    redirect_to dashboard_path
  end

  private

  def set_contacts_csv_upload_status
    if flash[:csv_upload_success]
      if current_user.initial_setup?
        # On dashboard view display as notice instead.
        flash.now[:notice] = flash[:csv_upload_success]
      else
        @csv_upload_success_message = flash[:csv_upload_success]
      end
      flash.delete(:csv_upload_success)
    end
  end

end
