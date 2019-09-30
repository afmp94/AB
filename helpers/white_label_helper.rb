module WhiteLabelHelper

  def white_label_image_name(image_filename, subdomain)
    base_image = image_filename

    if white_label_domain = WhiteLabelDomain.find_by(domain: subdomain)
      "#{white_label_domain.domain}-#{base_image}"
    else
      "ab-#{base_image}"
    end
  end

  def white_labeled_app_name(subdomain)
    if white_label_domain = WhiteLabelDomain.find_by(domain: subdomain)
      white_label_domain.name
    else
      "AgentBright"
    end
  end

  def white_labeled_company_name(subdomain)
    if white_label_domain = WhiteLabelDomain.find_by(domain: subdomain)
      white_label_domain.company_name
    else
      "AgentBright"
    end
  end

end
