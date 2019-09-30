class PropertyApiResearchService

  attr_accessor :property, :image, :full_address

  def initialize(options)
    if options[:property_id]
      @property = Property.find(options[:property_id])
    else
      @full_address = options[:full_address]
    end
  end

  def call_api
    property_info = "" # call_api_and_get_parsed_response
    save_property_image(property_info)
  end

  def get_property_info
    nil # call_api_and_get_parsed_response
  end

  # def property_api_url
  #   address = property ? property.full_address : full_address
  #   api_url = "https://www.kimonolabs.com/api/ondemand/9ztboodu?apikey=d8e92ec2fd98cfd1869e207278a6df91"
  #   escaped_address = CGI.escape(address)

  #   "#{api_url}&kimpath2=#{escaped_address}"
  # end

  # def get_response
  #   begin
  #     RestClient.get(property_api_url)
  #   rescue Exception => exception
  #     track_analytics("Property API Exception", exception) unless Rails.env.test?
  #     return false
  #   end
  # end

  def parse_response(response)
    JSON.parse(response)
  end

  def save_property_image(property_info)
    if property_info
      data = property_info["results"]["property_details"][0] rescue ""
      if data.blank?

      else
        property_image = data["image"]["src"] rescue ""
        _url = data["url"]
        _beds = data["beds"]
        _baths = data["baths"]
        _lot_size = data["lot_size"]
        _year_built = data["year_built"]
        _square_feet = data["square_feet"]
        _mls_number = data["mls_number"]
        _description = data["description"]
      end
    end

    save_image_and_property(property_image)
  end

  # def call_api_and_get_parsed_response
  #   Get the API
  #   api_response = get_response
  #   Parse the API response
  #   result = parse_response(api_response) if api_response
  #   save_result_to_api_response_model(result) if result
  #   report_parsing_result(result)
  #   result
  # end

  private

  def save_result_to_api_response_model(result)
    response_model = ApiResponse.new
    response_model.api_type = "kimono"
    response_model.api_called_at = Time.zone.now
    response_model.status = result["lastrunstatus"]
    response_model.message = "Kimono API was just called and responded
                             with the following results => #{result['results']} .
                             Kimono last called successfully
                             at #{result['lastsuccess']}"[0, 250] # avoid pg string error
    response_model.save!
  end

  def save_image_and_property(property_image)
    if property_image.present?
      save_image(property_image)
    elsif @property.address # save map information
      image_url = google_image_url(@property)
      save_image(image_url)
    end
  end

  def save_image(property_url)
    if property_url
      @image = Image.new(remote_file_url: property_url)
      @image.save!
      @property.property_image = @image
      @property.save!
    end
  end

  def google_image_url(property)
    address = property.address
    full_address = convert_to_full_address(address)

    GoogleApi::MapsApiService.new(full_address).google_image_url
  end

  def track_analytics(event, result=nil)
    Analytics.new.track(
      event: event,
      properties: { result: result }
    )
  end

  def report_parsing_result(result)
    track_analytics("Property API Run Failed", result) unless Rails.env.test?
  end

  def convert_to_full_address(address)
    address_info = [address.street, address.city, address.state]
    joiner = "+"

    address_info.select(&:present?).map do |info|
      info.gsub(" ", joiner)
    end.join(joiner)
  end

end
