class MktcampaignsController < ApplicationController

  before_action :load_mktcampaign, only: %i(destroy edit show update)

  def index
    page = params[:page].presence || 1

    @mktcampaigns = Mktcampaign.all.page(page).per(Mktcampaign::PER_PAGE)
  end

  def show
    load_general_params
  end

  def new
    @mktcampaign = Mktcampaign.new
    load_general_params
  end

  def edit
    render
  end

  def create
    @mktcampaign = Mktcampaign.new(mktcampaign_params)

    respond_to do |format|
      if @mktcampaign.save
        format.html { redirect_to mktcampaigns_path, notice: "Mktcampaign was successfully created." }
        format.json { render action: "show", status: :created, location: @mktcampaign }
      else
        format.html do
          flash.now[:danger] = "Please check your entry and try again."
          render :new
        end
        format.json { render json: @mktcampaign.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @mktcampaign.update(mktcampaign_params)
        format.html { redirect_to mktcampaigns_path, notice: "Mktcampaign was successfully updated." }
        format.json { head :no_content }
      else
        format.html do
          flash.now[:danger] = "Please check your entry and try again."
          render :edit
        end
        format.json { render json: @mktcampaign.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @mktcampaign.destroy
    respond_to do |format|
      format.html { redirect_to mktcampaigns_url }
      format.json { head :no_content }
    end
  end

  def search
    @mktcampaigns = Search::Mktcampaigns.new(
      search_term: params[:search_term],
      order_by: params[:order_by],
      sort_direction: params[:sort_direction],
      page: params[:page]
    ).process

    render layout: false
  end

  def destroy_multiple
    Mktcampaign.transaction do
      Mktcampaign.where(id: params[:ids]).destroy_all
    end

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  private

  def load_mktcampaign
    @mktcampaign = Mktcampaign.find(params[:id])
    load_general_params
  end

  def load_general_params
    @media_types = Media.order("num_order")
    @frequency_types = Frequency.order("freq_order")
  end

  def mktcampaign_params
    params.require(:mktcampaign).permit(
      :cost,
      :end_date_at,
      :frequency_id,
      :media_id,
      :name,
      :start_date_at,
    )
  end

end
