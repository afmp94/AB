class MarketingCenterController < ApplicationController

  def index
    @marketing_center_presenter = MarketingCenterPresenter.new(current_user)
    @contact_activity = current_user.contact_activities.new
  end

end
