class Search::Announcements

  attr_reader :search_term, :order_by, :sort_direction, :page

  def initialize(search_term: nil, order_by:, sort_direction:, page: nil)
    @search_term    = search_term
    @order_by       = order_by
    @sort_direction = sort_direction
    @page           = page
  end

  def process
    announcements = if search_term.present?
                      Announcement.search_message(search_term)
                    else
                      Announcement.all
                    end

    announcements.page(page).order("#{order_by} #{sort_direction}").per(Announcement::PER_PAGE)
  end

end
