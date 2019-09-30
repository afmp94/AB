class TeamGroupsController < ApplicationController

  before_action :must_be_team_group_owner, only: :edit

  def new
    @catalog = Catalog.new

    render layout: "landing_pages"
  end

  def edit
    @team_group = current_team_group
  end

end
