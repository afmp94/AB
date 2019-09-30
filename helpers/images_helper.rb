module ImagesHelper

  def display_fileinput_class(image)
    if image
      "ab-image-exists"
    else
      "ab-use-placeholder"
    end
  end

end
