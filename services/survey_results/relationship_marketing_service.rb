module SurveyResults

  class RelationshipMarketingService < BaseService

    def contact_size
      @_contact_size ||= survey_result.size_of_database
    end

    def contact_size_score
      @_contact_size_score ||= SurveyResult::SIZE_OF_DATABASE_SCORING[contact_size]
    end

    def contact_size_in_percentage
      return @_contact_size_in_percentage if @_contact_size_in_percentage.present?
      @_contact_size_in_percentage = score_in_percentage(contact_size_score, contact_size_max_score)
    end

    def personal_marketing
      @_personal_marketing ||= survey_result.daily_personal_marketing_effort
    end

    def personal_marketing_score
      @_personal_marketing_score ||= SurveyResult::DAILY_PERSONAL_MARKETING_EFFORT_SCORING[personal_marketing]
    end

    def personal_marketing_in_percentage
      @_personal_marketing_in_percentage ||= score_in_percentage(personal_marketing_score, personal_marketing_max_score)
    end

    def past_clients
      @_past_clients ||= survey_result.past_clients_touch
    end

    def past_clients_score
      @_past_clients_score ||= SurveyResult::PAST_CLIENTS_TOUCH_SCORING[past_clients]
    end

    def past_clients_in_percentage
      @_past_clients_in_percentage ||= score_in_percentage(past_clients_score, past_clients_max_score)
    end

    def track_referrals
      @_track_referrals ||= survey_result.referral_system
    end

    def track_referrals_score
      @_past_clients_score ||= SurveyResult::REFERRAL_SYSTEM_SCORING[track_referrals]
    end

    def score
      return @_relationship_marketing_score if @_relationship_marketing_score.present?
      @_relationship_marketing_score = 0

      [contact_size_score, personal_marketing_score, past_clients_score, track_referrals_score].each do |_score|
        @_relationship_marketing_score += _score
      end

      if @_relationship_marketing_score > total_score
        raise "Count #{@_relationship_marketing_score} is greater than total score #{total_score}"
      end

      @_relationship_marketing_score
    end

    def total_score_in_percentage
      @_total_score_in_percentage ||= score_in_percentage(score, total_score)
    end

    def total_score
      @_total_score ||= SurveyResult::SIZE_OF_DATABASE_SCORING.values.max +
                        SurveyResult::DAILY_PERSONAL_MARKETING_EFFORT_SCORING.values.max +
                        SurveyResult::PAST_CLIENTS_TOUCH_SCORING.values.max +
                        SurveyResult::REFERRAL_SYSTEM_SCORING.values.max
    end

    private

    def contact_size_max_score
      SurveyResult::SIZE_OF_DATABASE_SCORING.values.max
    end

    def past_clients_max_score
      SurveyResult::PAST_CLIENTS_TOUCH_SCORING.values.max
    end

    def personal_marketing_max_score
      SurveyResult::DAILY_PERSONAL_MARKETING_EFFORT_SCORING.values.max
    end

  end

end
