class Superadmin::NylasDashboardController < ApplicationController

  before_action :must_be_super_admin

  def index
    @webhooks = NylasApi::Admin.new.webhooks
  end

end
