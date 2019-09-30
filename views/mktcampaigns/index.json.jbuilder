json.array!(@mktcampaigns) do |mktcampaign|
  json.extract! mktcampaign, :name, :type, :start_date_at, :end_date_at, :cost, :recurring, :frequency
  json.url mktcampaign_url(mktcampaign, format: :json)
end
