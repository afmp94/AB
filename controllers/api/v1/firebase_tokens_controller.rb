class Api::V1::FirebaseTokensController < Api::V1::BaseController

  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user_using_x_auth_token
  before_action      :authenticate_user_by_token!

  def update
    @result = Api::V1::FirebaseTokens::Update.call(
      user: current_user,
      token: params[:fcm_token],
      device: params[:device_id],
      android: params[:android]
    )

    head @result
  end

end
