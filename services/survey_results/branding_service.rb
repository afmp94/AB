module SurveyResults

  class BrandingService < BaseService

    def testimonials
      @_testimonials ||= survey_result.testimonials_current
    end

    def testimonials_score
      @_testimonials_score ||= SurveyResult::TESTIMONIALS_CURRENT_SCORING[testimonials]
    end

    def testimonials_score_in_percentage
      @_testimonials_score_in_percentage ||= score_in_percentage(testimonials_score, testimonials_max_score)
    end

    def headshot
      @_headshot ||= survey_result.headshot_current
    end

    def headshot_score
      @_headshot_score ||= SurveyResult::HEADSHOT_CURRENT_SCORING[headshot]
    end

    def bio
      @_bio ||= survey_result.bio_current
    end

    def bio_score
      @_bio_score ||= SurveyResult::BIO_CURRENT_SCORING[bio]
    end

    def website
      @_website ||= survey_result.profile_broker_pages_current
    end

    def website_score
      @_website_score ||= SurveyResult::PROFILE_BROKER_PAGES_CURRENT_SCORING[website]
    end

    def online_profiles
      @_online_profiles ||= survey_result.online_profiles_current
    end

    def online_profiles_score
      @_online_profiles_score ||= SurveyResult::ONLINE_PROFILES_CURRENT_SCORING[online_profiles]
    end

    def score
      return @branding_score if @branding_score.present?
      @branding_score = 0

      [testimonials_score, headshot_score, bio_score, website_score, online_profiles_score].each do |_score|
        @branding_score += _score
      end

      if @branding_score > total_score
        raise "Count #{@branding_score} is greater than total_score #{total_score}"
      end

      @branding_score
    end

    def total_score_in_percentage
      @branding_score_in_percentage ||= score_in_percentage(score, total_score)
    end

    def total_score
      @_total_score ||= SurveyResult::TESTIMONIALS_CURRENT_SCORING.values.max +
                        SurveyResult::HEADSHOT_CURRENT_SCORING.values.max +
                        SurveyResult::BIO_CURRENT_SCORING.values.max +
                        SurveyResult::PROFILE_BROKER_PAGES_CURRENT_SCORING.values.max +
                        SurveyResult::ONLINE_PROFILES_CURRENT_SCORING.values.max
    end

    def testimonials_max_score
      SurveyResult::TESTIMONIALS_CURRENT_SCORING.values.max
    end

  end

end
