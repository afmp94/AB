module GoogleTagsHelper

  def gtm_auth
    case Rails.env
    when "production"
      "lEuT86UOvOKvx8xLuTVQ8g"
    when "staging"
      "W2eoOz134cVY4B8tGW82TQ"
    else
      "yRmeKeS0WTRzmh_sK_JlVw"
    end
  end

  def gtm_preview
    case Rails.env
    when "production"
      "env-2"
    when "staging"
      "env-7"
    else
      "env-6"
    end
  end

end
