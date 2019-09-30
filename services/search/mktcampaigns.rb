class Search::Mktcampaigns

  attr_reader :search_term, :order_by, :sort_direction, :page

  def initialize(search_term: nil, order_by:, sort_direction:, page: nil)
    @search_term    = search_term
    @order_by       = order_by
    @sort_direction = sort_direction
    @page           = page
  end

  def process
    mktcampaigns = if search_term.present?
                     Mktcampaign.search_name(search_term)
                   else
                     Mktcampaign.all
                   end

    mktcampaigns.page(page).order("#{order_by} #{sort_direction}").per(Mktcampaign::PER_PAGE)
  end

end
