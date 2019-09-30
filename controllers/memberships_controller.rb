class MembershipsController < ApplicationController

  before_action :must_be_team_group_owner

  def destroy
    user = current_user.users.find(params[:id])
    if user == current_user
      flash[:notice] = "You cannot remove yourself from the team group."
    else
      current_team_group.remove_user(user)
      flash[:notice] = "#{user.name} has been removed."
    end
    redirect_to edit_team_group_path
  end

end
