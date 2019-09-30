class ShowingsController < ApplicationController

  before_action :set_showing, only: [:show, :edit, :update, :destroy]

  def index
    @showings = Showing.all
  end

  def show
    @showing = Showing.find(params[:id])
    render
  end

  def new
    @showing = Showing.new
    @showing.lead_id = params[:lead_id]
  end

  def edit
    render
  end

  def update
    if @showing.update(showing_params)
      redirect_to lead_path(@showing), notice: "Showing successfully updated!"
    else
      format.html do
        flash.now[:danger] = "Please check your entry and try again."
        render :edit
      end
    end
  end

  def create
    @showing = Showing.new(showing_params)

    respond_to do |format|
      if @showing.save
        format.html { redirect_to lead_path(@showing),  notice: "Showing successfully created!" }
        format.json { render action: "showing", status: :created, location: @contract }
      else
        format.html do
          flash.now[:danger] = "Please check your entry and try again."
          render :new
        end
        format.json { render json: @contract.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @showing.destroy

    respond_to do |format|
      format.html { redirect_to showings_path }
      format.json { head :no_content }
    end
  end

  def showing_params
    params.require(:showing).permit(:lead_id, :status, :address1, :city, :state, :zip,
                                    :date_time, :comments, :mls_number, :listing_agent,
                                    :email_request_to_agent, :requested, :confirmed, :list_price)
  end

  def set_showing
    @showing = Showing.find(params[:id])
  end

end
