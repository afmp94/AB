module GoogleHelper

  def login_url
    url = "https://accounts.google.com/o/oauth2/auth?"\
          "scope=#{ApisController::CLIENT_SCOPE}&"\
          "redirect_uri=#{redirect_uri}&"\
          "response_type=code&"\
          "client_id=#{ApisController::CLIENT_ID}&"\
          "access_type=offline&"\
          "approval_prompt=force"

    URI.parse(URI.encode(url.strip))
  end

  def get_tokens(code)
    _params = {
      code: code,
      controller: "apis",
      action: "create",
      client_id: ApisController::CLIENT_ID,
      client_secret: ApisController::CLIENT_SECRET,
      redirect_uri: redirect_uri,
      grant_type: "authorization_code",
    }

    url = URI.parse(google_api_uri)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE # You should use VERIFY_PEER in production

    # Make request for tokens
    request = Net::HTTP::Post.new("/oauth2/v3/token")
    request.set_form_data(_params)
    response = http.request(request)

    parse_json(response)
  end

  def refresh_token(user_id)
    user = User.find(user_id)

    params["refresh_token"] = user.refresh_token
    params["client_id"] = ApisController::CLIENT_ID
    params["client_secret"] = ApisController::CLIENT_SECRET
    params["grant_type"] = "refresh_token"

    http = initialize_http_library

    # Make request for tokens
    request = Net::HTTP::Post.new("/o/oauth2/token")
    request.set_form_data(params)
    response = http.request(request)

    save_and_return_access_token(user: user, response: response)
  end

  def valid_token?(access_token)
    path = "/oauth2/v1/tokeninfo"

    http = initialize_http_library

    # Make request to API
    request = Net::HTTP::Get.new(path)
    request["Authorization"] = "Bearer " + access_token
    response = http.request(request)

    result = parse_json(response)

    if !result["error"].nil? && result["error"] == "invalid_token"
      false
    else
      true
    end
  end

  def call_api(path, access_token)
    url = URI.parse(google_api_uri)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE # You should use VERIFY_PEER in production

    # Make request to API
    request = Net::HTTP::Get.new(path)
    request["Authorization"] = "Bearer #{access_token}"
    response = http.request(request)

    parse_json(response)
  end

  private

  def initialize_http_library
    url = URI.parse("https://accounts.google.com")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    # http.verify_mode = OpenSSL::SSL::VERIFY_NONE # You should use VERIFY_PEER in production
    http
  end

  def parse_json(response)
    JSON.parse(response.body)
  end

  def save_and_return_access_token(user:, response:)
    # Parse the response
    user_tokens = parse_json(response)

    # Save the new access_token to the user
    user.update(
      access_token: user_tokens["access_token"],
      expires: user_tokens["expires_in"]
    )

    # Return the new access_token
    user_tokens["access_token"]
  end

  def redirect_uri
    "#{Rails.application.secrets.url_with_port}/googleoauth2callback"
  end

  def google_api_uri
    "https://www.googleapis.com"
  end

end
