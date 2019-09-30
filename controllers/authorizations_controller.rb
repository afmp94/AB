class AuthorizationsController < ApplicationController

  def destroy
    @authorization = Authorization.find(params[:id])
    @authorization.destroy
    redirect_to edit_integrations_path
  end

  def add_nylas_email_address
    if params[:already_connected_with_nylas] == "true"
      NylasApi::ImportContactsService.new(current_user).delay.process
      flash[:notice] = "Contacts import will start soon"

      redirect_to dashboard_path
    else
      user_email   = params[:email]
      callback_url = url_for(action: "nylas_login_callback")
      redirect_to url_for_authentication(callback_url, user_email, state: params[:from_page])
    end
  end

  def nylas_login_callback
    if params[:code].present? && save_user_token(fetch_new_token)
      flash[:notice] = if params[:state] == "import_contacts"
                         "We are connecting your email and contacts import will start soon."
                       else
                         "We are connecting your email - it may take a few minutes."
                       end
    else
      flash[:danger] = "Sorry there was an error while connecting your "\
        "account. Please try again or contact support@agentbright.com."
    end

    redirect_to path_for_redirect
  end

  def authorization_params
    params.require(:authorization).permit(:email,
                                          :provider,
                                          :uid,
                                          :user_id,
                                          :token,
                                          :secret,
                                          :first_name,
                                          :last_name,
                                          :name,
                                          :link,
                                          :created_at,
                                          :updated_at,
                                          :refresh_token,
                                          :refresh_expires)
  end

  def delete_nylas_token
    account_id_to_delete = current_user.nylas_account_id
    set_current_user_nylas_attributes_to_nil

    if NylasApi::Admin.new(account_id_to_delete).downgrade && current_user.save
      flash[:notice] = "Your account is successfully disconnnected!"
    else
      flash[:danger] = "Sorry there was an error terminating your "\
        "account. Please try again or contact support@agentbright.com."
    end

    redirect_to edit_integrations_path
  end

  def clear_nylas_settings
    if current_user.super_admin?
      current_user.clear_nylas_settings!
      flash[:notice] = "Your account is successfully cleared!"
    else
      flash[:danger] = "You don't have permission for this action!"
    end

    redirect_to edit_integrations_path
  end

  def update_nylas_calendar_setting
    user = current_user
    user.nylas_calendar_setting_id = set_calendar_id
    if user.save
      redirect_to(
        edit_integrations_url,
        notice: "Successfully updated your calendar setting, please check "\
          "your dahsboard."
      )
    else
      redirect_to(
        edit_integrations_url,
        danger: "Sorry there was an error updating your calendar setting, "\
          "please try again."
      )
    end
  end

  def url_for_authentication(redirect_uri, login_hint="", options={})
    params = {
      client_id: nylas_id,
      trial: options.fetch(:trial, false),
      response_type: "code",
      scope: "email",
      login_hint: login_hint,
      redirect_uri: redirect_uri
    }

    if options.has_key?(:state)
      params[:state] = options[:state]
    end

    "https://api.nylas.com/oauth/authorize?" + params.to_query
  end

  private

  def nylas
    @_nylas ||= Nylas::API.new(
      app_id: nylas_id,
      app_secret: nylas_secret,
      access_token: current_user.nylas_token
    )
  end

  def nylas_id
    Rails.application.secrets.nylas[:id]
  end

  def nylas_secret
    Rails.application.secrets.nylas[:secret]
  end

  def fetch_new_token
    nylas_token = Util.token_for_code(params[:code], nylas_id, nylas_secret)
    nylas_token
  rescue Nylas::APIError => e
    save_api_error_response(e)
    nil
  rescue SocketError => e
    save_api_error_response(e)
    nil
  end

  def save_api_error_response(e)
    ApiResponse.create!(
      api_type: "nylasapp",
      api_called_at: Time.current,
      status: "error",
      message: "Error occured while trying to connect
          with Nylas => #{e.inspect}"[0, 250]
    )
  end

  def set_calendar_id
    if params["calendar"]["id"] == "nil"
      nil
    else
      params["calendar"]["id"]
    end
  end

  def save_user_token(token)
    token_status = false
    if token.present?
      current_user.update!(nylas_token: token)
      upgrade_account(current_user)
      SetUserNylasAccountJob.set(wait: 15.seconds).perform_later(current_user.id, params[:state])
      token_status = true
    end
    token_status
  end

  def set_current_user_nylas_attributes_to_nil
    current_user.attributes = {
      nylas_account_id: nil,
      nylas_account_status: nil,
      nylas_calendar_setting_id: nil,
      nylas_connected_email_account: nil,
      nylas_sync_status: nil,
      nylas_token: nil,
      nylas_trial_status_set_at: nil
    }
  end

  def path_for_redirect
    if params[:state] == "import_contacts" && !current_user.onboarding_completed?
      profile_steps_path(id: "other_information")
    elsif params[:state] == "sync_email"
      profile_steps_path(id: "wicked_finish")
    else
      edit_integrations_path
    end
  end

  def upgrade_account(user)
    nylas_account = NylasApi::Account.new(user.nylas_token)
    nylas_admin = NylasApi::Admin.new(nylas_account.account_id)
    if nylas_admin.billing_status_cancelled?
      nylas_admin.upgrade
    end
  end

end
