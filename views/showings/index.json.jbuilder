json.array!(@showings) do |showing|
  json.extract! showing, :id, :lead_id, :status, :address1, :city, :state, :zip, :date_time, :comments, :mls_number, :listing_agent, :email_request_to_agent, :requested, :confirmed, :list_price
  json.url showing_url(showing, format: :json)
end
