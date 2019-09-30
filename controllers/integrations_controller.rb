class IntegrationsController < ApplicationController

  require "dotloop-ruby"

  def create
    url = dotloop_auth.url_for_authentication(
      url_for(action: "dotloop_response"),
      redirect_on_deny: true
    )
    redirect_to url
  end

  def destroy
    DotloopService.new.refresh_dotloop_token(current_user)
    set_dotloop_client = DotloopService.new.set_dotloop_client(current_user)
    response = RestClient.post("https://auth.dotloop.com/oauth/token/revoke", token: set_dotloop_client.access_token)
    if response.code == 200
      current_user.integrations.first.destroy
      flash[:notice] = "Successfully dicconnected your Dotloop account"
    else
      flash[:alert] = "An error occured"
    end
    redirect_to edit_third_party_integrations_url
  end

  def dotloop_response
    flash_msg(params)
    if params[:code].present?
      code = params[:code]
      response = dotloop_auth.acquire_access_and_refresh_token(
        code,
        redirect_uri: url_for(action: "dotloop_response")
      )
      if response["access_token"].present?
        access_token = response["access_token"]
        refresh_token = response["refresh_token"]
        save_client(access_token, refresh_token)
        flash[:notice] = "Successfully connected to your Dotloop account"
      end
    end
    redirect_to edit_third_party_integrations_url
  end

  def flash_msg(params)
    if params[:error].present?
      flash[:alert] = params[:error_description]
    end
  end

  def save_client(access_token, refresh_token)
    dotloop_client = Dotloop::Client.new(access_token: access_token)
    account = dotloop_client.account
    f_name = account[:data][:first_name]
    l_name = account[:data][:last_name]
    email = account[:data][:email]
    profile_id = account[:data][:default_profile_id]
    account_id = account[:data][:id]
    Integration.create(
      first_name: f_name,
      last_name: l_name,
      email: email,
      access_token: access_token,
      refresh_token: refresh_token,
      default_profile_id: profile_id,
      account_id: account_id,
      user_id: current_user.id,
      name: "dotloop"
    )
  end

  private

  def dotloop_auth
    DotloopService.new.dotloop_auth
  end

end
