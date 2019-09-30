class ConfirmationsController < Devise::ConfirmationsController

  def show
    user = User.find_by(confirmation_token: params[:confirmation_token])

    if user.confirmed?
      flash[:notice] = "Your email address is already verified"
    else
      user.update(confirmed_at: Time.current)
      flash[:notice] = "Successfully confirmed your email address"
    end

    return redirect_to(profile_path) if current_user

    redirect_to(login_path)
  end

end
