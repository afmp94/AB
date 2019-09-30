class UserSettings::AvailableNumbersController < ApplicationController

  def index
    @available_numbers = Twilio::AvailableNumbers.call(
      area_code: params[:area_code]
    )
  end

end