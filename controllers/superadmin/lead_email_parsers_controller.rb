class Superadmin::LeadEmailParsersController < ApplicationController

  before_action :authenticate_superadmin_user!

  def create
    @lead_email = LeadEmail.find(params[:lead_email_id])

    @result = if @lead_email
                LeadEmailProcessingJob.perform_later(@lead_email.id)
              end
  end

end
