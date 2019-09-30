module SurveyResults

  class BaseService

    attr_reader :survey_result

    def initialize(survey_result)
      @survey_result = survey_result
    end

    private

    def score_in_percentage(score, total_score)
      ((score.to_f / total_score.to_f) * 100).round(2)
    end

    def property_is_selected?(property)
      [true].include?(property)
    end

  end

end
