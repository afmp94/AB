class UserSettings::LeadSettingsController < ApplicationController

  before_action :load_lead_settings

  def edit
    render
  end

  def update
    respond_to do |format|
      if @lead_setting.update(lead_settings_params)
        format.html do
          flash[:notice] = "Successfully updated Notification Settings."
          redirect_to request.referer || edit_user_settings_lead_settings_path
        end
        format.js { render json: @lead_setting, head: :ok }
      else
        format.html do
          flash[:danger] = "Error updating Notification Settings."
          redirect_to request.referer || edit_user_settings_lead_settings_path
        end
        format.js do
          render(
            json: { errors: @lead_setting.errors.full_messages },
            status: 422
          )
        end
      end
    end
  end

  def auto_responder_update
    respond_to do |format|
      if @lead_setting.update_attributes(lead_settings_params)
        format.html do
          message = "Successfully updated Autoresponder Settings."
          redirect_to(
            lead_notifications_user_settings_lead_settings_path,
            notice: message
          )
        end
        format.js { render json: @lead_setting, head: :ok }
      else
        format.html { render "edit" }
        format.js do
          render(
            json: { errors: @lead_setting.errors.full_messages },
            status: 422
          )
        end
      end
    end
  end

  def away_settings_update
    if @lead_setting.update_attributes(lead_settings_params)
      redirect_to(
        away_settings_user_settings_lead_settings_path,
        notice: "Successfully updated Away Settings"
      )
    else
      render "away_settings"
    end
  end

  def lead_forward_update
    if @lead_setting.update_attributes(lead_settings_params)
      redirect_to(
        user_settings_lead_groups_path,
        notice: "Successfully updated Lead Forward Settings."
      )
    else
      render "edit"
    end
  end

  def lead_broadcast_update
    if @lead_setting.update_attributes(lead_settings_params)
      redirect_to(
        user_settings_lead_groups_path,
        notice: "Successfully updated Lead Broadcast Settings."
      )
    else
      render "edit"
    end
  end

  def toggle_auto_responder
    if @lead_setting.toggle_auto_responder
      redirect_to(
        lead_notifications_user_settings_lead_settings_path,
        notice: "Successfully changed Autoresponder status"
      )
    else
      redirect_to(
        lead_notifications_user_settings_lead_settings_path,
        danger: "Error changing Autoresponder status"
      )
    end
  end

  def toggle_forward_to_lead_group
    @lead_setting.toggle_forward_to_lead_group
    init_view_service
  end

  def toggle_broadcast_to_lead_group
    @lead_setting.toggle_broadcast_to_lead_group
    init_view_service
  end

  def toggle_lead_source_status
    if @lead_setting.toggle_lead_parser_status(params[:lead_source])
      redirect_to(
        lead_services_user_settings_lead_settings_path,
        notice: "Successfully changed lead source status for "\
          "#{params[:lead_source]}."
      )
    else
      redirect_to(
        lead_services_user_settings_lead_settings_path,
        danger: "Error changing lead source status for #{params[:lead_source]}."
      )
    end
  end

  def update_ab_email
    if @user.update(user_params)
      redirect_to(
        lead_services_user_settings_lead_settings_path,
        notice: "Successfully updated email address"
      )
    else
      flash.now[:danger] = "Error changing email address"
      render "edit"
    end
  end

  def quicklink
    render
  end

  def lead_notifications
    render
  end

  def lead_services
    render
  end

  def away_settings
    render
  end

  def send_daily_overall_recap
    current_user.send_daily_overall_recap_email
    redirect_to(
      user_settings_general_notifications_path,
      notice: "Email successfully sent."
    )
  end

  def send_next_action_reminder_sms
    current_user.send_next_action_reminder_sms
    redirect_to(
      lead_notifications_user_settings_lead_settings_path,
      notice: "SMS successfully sent."
    )
  end

  private

  def load_lead_settings
    @user = current_user
    @user.build_lead_setting_for_user!
    @lead_setting = @user.lead_setting
    init_view_service
  end

  def init_view_service
    @lead_setting_view_service = LeadSettingViewService.new(@lead_setting, current_user)
  end

  def user_params
    params.require(:user).permit(:ab_email_address, :id)
  end

  def lead_settings_params
    params.require(:lead_setting).permit(
      :auto_respond_body,
      :auto_respond_subject,
      :away,
      :broadcast_after_minutes,
      :daily_leads_recap,
      :daily_overall_recap,
      :daily_pipeline,
      :email_auto_respond,
      :followup_lead_email_permission,
      :followup_lead_sms_permission,
      :forward_after_minutes,
      :forward_lead_to_group,
      :lead_claimed_email_notification,
      :lead_claimed_sms_notification,
      :lead_unclaimed_email_notification,
      :lead_unclaimed_sms_notification,
      :new_lead_email_notification,
      :new_lead_sms_notification,
      :next_action_reminder_sms,
      :notification_time_interval,
      :quiet_hours,
      :quiet_hours_end,
      :quiet_hours_start,
      :receive_daily_client_activity_recap,
      :receive_sms_on_weekends,
      :vacation_end_at,
      :will_receive_morning_awaiting,
      broadcast_to_group_ids: [],
      forward_to_group_ids: [],
    )
  end

end
