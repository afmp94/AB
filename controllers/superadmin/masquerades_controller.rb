module Superadmin

  class MasqueradesController < ApplicationController

    before_action :check_super_admin_status
    skip_before_action :redirect_if_subscription_inactive, only: [:destroy]

    def create
      if masquerading?
        reverse_superadmin_and_redirect
      else
        session[:admin_id] = current_user.id
        session[:superadmin] = true
        user = User.find(params[:user_id])
        sign_in(user)
        redirect_to(root_path)
      end
    end

    def destroy
      sign_in(User.find(session[:admin_id]))
      session.delete(:admin_id)
      session.delete(:superadmin)
      redirect_to(admin_root_path, notice: "Stopped masquerading")
    end

    private

    def check_super_admin_status
      unless super_admin_signed_in? || User.find_by(id: session[:admin_id])&.super_admin
        flash[:error] = "You do not have permission to view that page."
        redirect_to root_url
      end
    end

    def reverse_superadmin_and_redirect
      session[:superadmin] = session[:superadmin] ? !session[:superadmin] : true
      redirect_back(fallback_location: dashboard_path)
    end

  end

end
