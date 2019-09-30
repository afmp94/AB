class Users::SessionsController < Devise::SessionsController

  skip_before_action :redirect_to_assessment_page, :redirect_if_subscription_inactive

  def new
    if params[:redirect_to].present?
      self.resource = resource_class.new(sign_in_params)
      store_location_for(resource, params[:redirect_to])
    end

    super do
      analytics.track_user_creation
    end
  end

  def assessment_new
    render
  end

  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?
    analytics.track_user_sign_in
    @location = after_sign_in_path_for(resource)
    respond_with resource, location: @location
  end

end
