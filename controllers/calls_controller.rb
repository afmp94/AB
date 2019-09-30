class CallsController < ApplicationController

  skip_before_action :authenticate_user!,        only: :create
  skip_before_action :verify_authenticity_token, only: :create

  def create
    @response = Calls::Create.call(called_number: params[:To])

    render xml: @response.text
  end

end
