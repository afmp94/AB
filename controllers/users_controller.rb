class UsersController < ApplicationController

  before_action :load_user, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_superadmin_user!, except: [
    :billing,
    :contacts_data,
    :send_email_confirmation_notification,
  ]

  skip_before_action :redirect_if_subscription_inactive

  def index
    @users = User.all
  end

  def show
    render
  end

  def update
    if @user.update(user_params)
      sign_in(@user == current_user ? @user : current_user, bypass: true)
      redirect_to(
        session[:referring_page] || profile_url,
        success: "Successfully updated your profile."
      )
    else
      flash[:danger] = "Could not save your profile. Please try again."
      render "users/registrations/edit"
    end
  end

  def billing
    @plans = Plan.all
  end

  def toggle_beta_features
    set_beta = !current_user.show_beta_features

    if current_user.update(show_beta_features: set_beta)
      redirect_back(fallback_location: dashboard_path, success: "Now #{set_beta ? 'showing' : 'hiding'} beta features.")
    else
      redirect_back(fallback_location: dashboard_path, danger: "Error toggling beta features.")
    end
  end

  def read_message_broadcast
    current_user.read_message_broadcasts.create(message_broadcast_id: params[:message_broadcast_id])
    # I had to add json: @controller.to_json, so that we can status '200' otherwise
    # it returns status '500'
    # TODO: Check better way to handle this without using extra json parameter.
    render status: 200, json: @controller.to_json
  end

  def contacts_data
    render json: current_user.contacts_data_in_json(params[:q])
  end

  def send_email_confirmation_notification
    current_user.send_confirmation_instructions

    flash[:notice] = "Confirmation email has been successfully sent to your email address"
    redirect_back(fallback_location: profile_path)
  end

  private

  def users_params
    params.require(:user).permit(:name, :email)
  end

  def load_user
    @user = User.find(params[:id])
  end

end
