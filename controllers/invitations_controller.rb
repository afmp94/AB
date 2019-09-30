class InvitationsController < ApplicationController

  before_action :must_be_team_group_owner

  def create
    if deliver_invitation
      redirect_with_notice
    else
      render_errors
    end
  end

  def destroy
    invitation = current_team_group.invitations.find(params[:id])
    invitation.destroy
    redirect_to edit_team_group_path, notice: "The invitation has been removed."
  end

  private

  def deliver_invitation
    @invitation = Invitation.new(invitation_attributes)
    @invitation.deliver
  end

  def redirect_with_notice
    redirect_to edit_team_group_path, notice: "Invitation sent."
  end

  def render_errors
    render :new
  end

  def invitations_attributes
    params.
      require(:invitation).
      permit(:email).
      merge(sender: current_user, team_group: current_team_group)
  end

end
