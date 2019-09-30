class Util

  def self.log_exception(exception)
    msg = exception.class.to_s; log msg
    msg = exception.to_s; log msg
    exception.backtrace.each do |line|
      log line
    end
  end

  def self.log msg
    Rails.logger.info msg
  end

  # To execute updates without tracking on Activity
  def self.without_tracking
    current = PublicActivity.enabled?
    PublicActivity.enabled = false
    yield
  ensure
    PublicActivity.enabled = current
  end

  def self.nylas_response(request_type, url, authorization, params={})
    require "uri"
    require "net/http"
    url = URI(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = if request_type == "post"
                Net::HTTP::Post.new(url)
              elsif request_type == "put"
                Net::HTTP::Put.new(url)
              else
                Net::HTTP::Get.new(url)
              end
    request["authorization"] = authorization
    request.body = params if params.present?
    response = http.request(request)
    response.read_body
  end

  def self.interpret_response(result, result_content, options={})
    condition = options[:result_parsed] || (options[:raw_response] && result.code.to_i == 200)
    response = if condition
                 result_content
               else
                 JSON.parse(result_content)
               end
    response
  rescue JSON::ParserError
    raise Nylas::APIError.new(400, "Unexpected Error")
  end

  def self.response_parse_error(result, response)
    if result.code.to_i != 200
      exc = Nylas.http_code_to_exception(result.code.to_i)
      if response.is_a?(Hash)
        raise exc.new(response["type"], response["message"], response.fetch("server_error", nil))
      end
    end
  end

  def self.token_for_code(code, nylas_id, nylas_secret)
    data_hash = { "client_id" => nylas_id, "client_secret" => nylas_secret,
                  "grant_type" => "authorization_code", "code" => code }

    ::RestClient.post("https://api.nylas.com/oauth/token", data_hash) do |response, _request, result|
      json = Util.interpret_response(result, response, expected_class: Object)
      Util.response_parse_error(result, json)
      return json["access_token"]
    end
  end

  def self.create_event(nylas_event)
    request_body = JSON.dump(
      "title" => nylas_event.title.to_s,
      "when" => Util.create_event_when(nylas_event.when),
      "location" => nylas_event.location.to_s,
      "description" => nylas_event.description.to_s,
      "calendar_id" => nylas_event.calendar_id.to_s
    )
    nylas_response("post",
                   "https://api.nylas.com/events",
                   nylas_event.api.client.access_token.to_s,
                   request_body)
  end

  def self.update_event(nylas_event)
    request_body = JSON.dump(
      "title" => nylas_event.title.to_s,
      "when" => Util.create_event_when(nylas_event.when),
      "location" => nylas_event.location.to_s,
      "description" => nylas_event.description.to_s
    )
    nylas_response("put",
                   "https://api.nylas.com/events/#{nylas_event.id}",
                   nylas_event.api.client.access_token.to_s,
                   request_body)
  end

  def self.create_event_when(nylas_event_when)
    send("#{nylas_event_when.object}_hash".to_sym, nylas_event_when)
  end

  def self.timespan_hash(nylas_event_when)
    event_start_time = nylas_event_when.start_time.to_i
    event_end_time = nylas_event_when.end_time.to_i
    {
      "start_time" => event_start_time.to_s,
      "end_time" => event_end_time.to_s
    }
  end

  def self.date_hash(nylas_event_when)
    {
      "date" => nylas_event_when.date.to_s
    }
  end

  def self.datespan_hash(nylas_event_when)
    {
      "start_date" => nylas_event_when.start_date.to_s,
      "end_date" => nylas_event_when.end_date.to_s
    }
  end

end
