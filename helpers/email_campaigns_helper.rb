module EmailCampaignsHelper

  def email_image_width(image)
    if image
      if image.width.nil?
        image.width = 200
      elsif image.width > 492
        492
      else
        image.width
      end
    end
  end

  def show_link_for_email_campaign(email_campaign)
    if email_campaign.sent? || email_campaign.pending?
      email_campaign_path(email_campaign)
    else
      if email_campaign.campaign_type == EmailCampaign::CAMPAIGN_TYPES[:basic]
        edit_basic_email_campaign_path(email_campaign)
      else
        edit_email_campaign_path(email_campaign)
      end
    end
  end

  def email_campapign_name(email_campaign)
    email_campaign.name.presence || "N/A"
  end

  def handle_disabled_class
    current_user.confirmed? ? "" : "disabled"
  end

  def unsubscribe_path_for(contact)
    token            = contact.try(:subscription_token)
    url_with_port    = Rails.application.secrets.url_with_port
    unsubscribe_path = public_unsubscribe_contact_path(subscription_token: token)

    url_with_port + unsubscribe_path
  end

end
