class AnnouncementsController < ApplicationController

  before_action :load_announcement, only: [:show, :edit, :update, :destroy]

  def index
    page = params[:page].presence || 1

    @announcements = Announcement.all.order("starts_at asc")
    @announcements = @announcements.page(page).per(Announcement::PER_PAGE)
  end

  def new
    @announcement = Announcement.new
  end

  def edit
    render
  end

  def show
    render
  end

  def update
    if @announcement.update(announcement_params)
      redirect_to announcements_path, notice: "Announcement successfully updated!"
    else
      render :edit
    end
  end

  def create
    @announcement = Announcement.new(announcement_params)

    respond_to do |format|
      if @announcement.save
        format.html { redirect_to announcements_path, notice: "Announcement successfully created!" }
        format.json { render action: "announcement", status: :created, location: @announcement }
      else
        format.html { render action: "new" }
        format.json { render json: @announcement.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @announcement.destroy

    respond_to do |format|
      format.html { redirect_to announcements_url }
      format.json { head :no_content }
    end
  end

  def destroy_multiple
    Announcement.transaction do
      Announcement.where(id: params[:ids]).destroy_all
    end

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  def hide
    ids = [params[:id], *cookies.signed[:hidden_announcement_ids]]
    cookies.permanent.signed[:hidden_announcement_ids] = ids
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.js
    end
  end

  def search
    @announcements = Search::Announcements.new(
      search_term: params[:search_term],
      order_by: params[:order_by],
      sort_direction: params[:sort_direction],
      page: params[:page]
    ).process

    render layout: false
  end

  private

  def announcement_params
    params.require(:announcement).permit(:message, :starts_at, :ends_at)
  end

  def load_announcement
    @announcement = Announcement.find(params[:id])
  end

end
