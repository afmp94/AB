module PropertiesHelper

  def property_image_or_location_image_url(property)
    if property.has_image?
      property.property_image.file.url
    else
      google_image_url(property)
    end
  end

  def google_image_url(property)
    address = property.address
    full_address = convert_to_full_address(address)

    GoogleApi::MapsApiService.new(full_address).google_image_url
  end

  def property_card_image_centering_style(property)
    if property.has_image?
      "background-position: 50% 50%;"
    else
      "background-position: 50% 50%;background-size: 125%;"
    end
  end

  def set_class_for_image_and_location(property)
    if property.has_image?
      "property-card-image"
    else
      "property-card-location"
    end
  end

  def property_card_image(property, gradient=true)
    if gradient == true
      background = "background: linear-gradient(rgba(0, 0, 0, 0.1), "\
                   "rgba(0, 0, 0, 0.5)), "\
                   "url('#{property_image_or_location_image_url(property)}')"
    else
      background = "background: url('#{property_image_or_location_image_url(property)}')"
    end

    content_tag(
      :div,
      "",
      class: "card-image #{set_class_for_image_and_location(property)}",
      style: "#{background};background-size:300%;"\
             "background-position:50% 50%;"\
             "background-repeat:no-repeat;"
    )
  end

  private

  def convert_to_full_address(address)
    address_info = [address.street, address.city, address.state]
    joiner = "+"

    address_info.select(&:present?).map do |info|
      info.gsub(" ", joiner)
    end.join(joiner)
  end

end
