module SurveyResults

  class ProspectConversionService < BaseService

    def follow_up_system
      @_follow_up_system ||= survey_result.follow_up_system
    end

    def follow_up_system_score
      @_follow_up_system_score ||= SurveyResult::FOLLOW_UP_SYSTEM_SCORING[follow_up_system]
    end

    def prospect_materials
      @_prospect_materials ||= (survey_result.system_for_transactions || false)
    end

    def prospect_materials_score
      @_prospect_materials_score ||= SurveyResult::SYSTEM_FOR_TRANSACTIONS_SCORING[prospect_materials]
    end

    def score
      return @_prospect_conversion_score if @_prospect_conversion_score.present?
      @_prospect_conversion_score = 0

      [follow_up_system_score, prospect_materials_score].each do |_score|
        @_prospect_conversion_score += _score
      end

      if @_prospect_conversion_score > total_score
        raise "Score #{@_prospect_conversion_score} is greater than total score #{total_score}"
      end

      @_prospect_conversion_score
    end

    def total_score_in_percentage
      @_total_score_in_percentage ||= score_in_percentage(score, total_score)
    end

    def total_score
      @_total_score ||= SurveyResult::FOLLOW_UP_SYSTEM_SCORING.values.max +
                        SurveyResult::SYSTEM_FOR_TRANSACTIONS_SCORING.values.max
    end

  end

end
