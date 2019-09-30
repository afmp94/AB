class Api::V1::ContactsController < Api::V1::BaseController

  skip_before_action :authenticate_user!,                   only: [:import_ios]
  skip_before_action :verify_authenticity_token,            only: [:import_ios]
  skip_before_action :authenticate_user_using_x_auth_token, only: [:import_ios]
  before_action      :authenticate_user_by_token!,          only: [:import_ios]

  def index
    @contacts = Contact.limit(500)

    if @contacts
      # render json: @contacts
      render "contacts/index"
    else
      respond_with_error("Contacts not found.", :not_found)
    end
  end

  def import_ios
    @job_id = Contact::ImportIOS.(json: ios_params, user: current_user)

    head :ok
  end

  private

  def ios_params
    params.permit!.fetch(:_json, {})
  end

end
