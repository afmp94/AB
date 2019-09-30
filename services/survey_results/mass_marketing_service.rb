module SurveyResults

  class MassMarketingService < BaseService

    def email_marketing
      @_email_marketing ||= survey_result.monthly_email_newsletter_sent
    end

    def email_marketing_score
      @_email_marketing_score ||= SurveyResult::MONTHLY_EMAIL_NEWSLETTER_SENT_SCORING[email_marketing]
    end

    def email_marketing_in_percentage
      @_email_marketing_in_percentage ||= score_in_percentage(email_marketing_score, email_marketing_max_score)
    end

    def mail_marketing
      @_mail_marketing ||= survey_result.monthly_print_sent
    end

    def mail_marketing_score
      @_mail_marketing_score ||= SurveyResult::MONTHLY_PRINT_SENT_SCORING[mail_marketing]
    end

    def mail_marketing_in_percentage
      @_mail_marketing_in_percentage ||= score_in_percentage(mail_marketing_score, mail_marketing_max_score)
    end

    def area_framing
      @_area_framing ||= survey_result.neighborhood_farming_cards_sent
    end

    def area_framing_score
      @_area_framing_score ||= SurveyResult::NEIGHBORHOOD_FARMING_CARDS_SENT_SCORING[area_framing]
    end

    def area_framing_in_percentage
      @_area_framing_in_percentage ||= score_in_percentage(area_framing_score, area_framing_max_score)
    end

    def social_media
      @_social_media ||= survey_result.social_media_engagement
    end

    def social_media_score
      @_social_media_score ||= SurveyResult::SOCIAL_MEDIA_ENGAGEMENT_SCORING[social_media]
    end

    def social_media_in_percentage
      @_social_media_in_percentage ||= score_in_percentage(social_media_score, social_media_max_score)
    end

    def score
      return @_mass_marketing_score if @_mass_marketing_score.present?
      @_mass_marketing_score = 0

      [email_marketing_score, mail_marketing_score, area_framing_score, social_media_score].each do |score|
        @_mass_marketing_score += score
      end

      if @_mass_marketing_score > total_score
        raise "Count #{@_relationship_marketing_score} is greater than total score #{total_score}"
      end

      @_mass_marketing_score
    end

    def total_score_in_percentage
      @_total_score_in_percentage ||= score_in_percentage(score, total_score)
    end

    def total_score
      @_total_score ||= SurveyResult::MONTHLY_EMAIL_NEWSLETTER_SENT_SCORING.values.max +
                        SurveyResult::MONTHLY_PRINT_SENT_SCORING.values.max +
                        SurveyResult::NEIGHBORHOOD_FARMING_CARDS_SENT_SCORING.values.max +
                        SurveyResult::SOCIAL_MEDIA_ENGAGEMENT_SCORING.values.max
    end

    private

    def email_marketing_max_score
      SurveyResult::MONTHLY_EMAIL_NEWSLETTER_SENT_SCORING.values.max
    end

    def mail_marketing_max_score
      SurveyResult::MONTHLY_PRINT_SENT_SCORING.values.max
    end

    def area_framing_max_score
      SurveyResult::NEIGHBORHOOD_FARMING_CARDS_SENT_SCORING.values.max
    end

    def social_media_max_score
      SurveyResult::SOCIAL_MEDIA_ENGAGEMENT_SCORING.values.max
    end

  end

end
