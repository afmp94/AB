class ApiResponseUpdateService

  attr_accessor :time_period

  def update_api_responses
    if time_to_ping_fullcontact?
      check_fullcontact_api
    end
  end

  def time_to_ping_fullcontact?
    fullcontact_pings = ApiResponse.where(api_type: "fullcontact.ping")

    if fullcontact_pings.length > 0
      last_ping = fullcontact_pings.last
      (Time.zone.now.to_i - last_ping.api_called_at.to_i) > 1800
    else
      true
    end
  end

  private

  def check_fullcontact_api
    @time_period = Time.current.strftime("%Y-%m")

    url = fullcontact_stats_url

    if response = fullcontact_response(url)
      begin
        hash = JSON.parse(response)
      rescue Exception => e
        save_api_response(
          status: "Error - JSON Parsing",
          message: "Error JSON parsing FullContact API response: #{e.inspect}"[0, 250]
        )

        hash = nil
        Rails.logger.info(
          "error in json parsing response in ApiResponseUpdateService#update_fullcontact_api_response -> #{e}"
        )
      end

      if hash
        save_api_response(
          status: hash["status"],
          message: metrics_message(hash["metrics"])
        )
      end
    end
  end

  def fullcontact_stats_url
    api_key = Rails.application.secrets.fullcontact_api_key
    URI("https://api.fullcontact.com/v2/stats.json?period=#{time_period}&apiKey=#{api_key}")
  end

  def fullcontact_response(url)
    Net::HTTP.get(url)
  rescue Exception => e
    save_api_error(
      status: "Error - Connecting",
      message: "Error in connecting with FullContact API => #{e.inspect}"[0, 250]
    )

    Rails.logger.info "error in ApiResponseUpdateService#update_fullcontact_api_response => #{e}"
    nil
  end

  def metrics_message(metrics)
    if metrics
      metrics.each do |metric|
        if metric["metricId"] == "200"
          "FullContact Successful API calls remaining this month(#{time_period}) : #{metric["remaining"]} "[0, 250]
        end
      end
    end
  end

  def save_api_response(status:, message:)
    ApiResponse.create(
      status: status,
      message: message,
      api_type: "fullcontact.ping",
      api_called_at: Time.current
    )
  end

end
