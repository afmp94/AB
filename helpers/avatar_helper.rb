module AvatarHelper

  def avatar(circular: false, color: nil, image: nil, size: "tiny", text: nil, additional_class: nil)
    if image
      image_tag(image, class: "ui #{circular ? 'circular' : ''} #{size} image")
    else
      content_tag(
        :span,
        text,
        class: "ab-avatar ab-avatar--#{size} ab-avatar--#{circular ? 'circular' : ''} ab-avatar--color-#{color} #{additional_class}"
      )
    end
  end

  def display_avatar(object, size: "mini", circular: true, additional_class: nil)
    text = if object&.class&.name == "User" || object&.class&.name == "Contact"
             object&.initials&.upcase
           else
             object&.initial&.upcase
           end

    avatar(
      image: object&.display_image&.file&.url,
      text: text || "N/A",
      size: size,
      circular: circular,
      color: object&.avatar_color,
      additional_class: additional_class
    )
  end

  def grade_avatar(contact, size: "mini", color: true)
    color_grade_class = if color
                          "ab-avatar--color-grade-#{contact&.grade}"
                        else
                          "ab-avatar--color-grade-"
                        end

    content_tag(
      :span,
      contact&.grade_to_s,
      class: "ab-avatar ab-avatar--#{size} ab-avatar--circular #{color_grade_class}"
    )
  end

  def display_initials_and_color_from_message(message, user, contact)
    user_or_contact = GetUserOrContactFromMessageService.process(message, user, contact)

    if user_or_contact.present?
      display_avatar(user_or_contact, size: :avatar)
    else
      names = message.from.map { |h| h.class == Hash ? h["name"] : h.name }
      first_name, last_name = names.first.split(" ")
      initials = get_initials_from_names(first_name, last_name)

      avatar(size: :avatar, text: initials, circular: true)
    end
  end

end
