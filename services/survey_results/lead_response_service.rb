module SurveyResults

  class LeadResponseService < BaseService

    def immediate_response
      @_immediate_response ||= survey_result.lead_response_measurement
    end

    def immediate_response_score
      @_immediate_response_score ||= SurveyResult::LEAD_RESPONSE_MEASUREMENT_SCORING[immediate_response]
    end

    def immediate_response_in_percentage
      @_immediate_response_in_percentage ||= score_in_percentage(immediate_response_score, immediate_response_max_score)
    end

    def lead_source_measurement
      @_lead_source_measurement ||= survey_result.lead_source_analysis
    end

    def lead_source_measurement_score
      @_lead_source_measurement_score ||= SurveyResult::LEAD_SOURCE_ANALYSIS_SCORING[lead_source_measurement]
    end

    def lead_retargeting
      @_lead_retargeting ||= survey_result.drip_campaigns_to_followup
    end

    def lead_retargeting_score
      @_lead_retargeting_score ||= SurveyResult::DRIP_CAMPAIGNS_TO_FOLLOWUP_SCORING[lead_retargeting]
    end

    def lead_retargeting_in_percentage
      @_lead_retargeting_in_percentage ||= score_in_percentage(lead_retargeting_score, lead_retargeting_max_score)
    end

    def automatic_lead_importing
      @_automatic_lead_importing ||= survey_result.use_crm
    end

    def automatic_lead_importing_score
      @_automatic_lead_importing_score ||= SurveyResult::USE_CRM_SCORING[automatic_lead_importing]
    end

    def automatic_lead_importing_in_percentage
      @_automatic_lead_importing_in_percentage ||= score_in_percentage(
        automatic_lead_importing_score,
        automatic_lead_importing_max_score
      )
    end

    def score
      return @_lead_response_score if @_lead_response_score.present?

      @_lead_response_score = 0

      [
        immediate_response_score,
        lead_source_measurement_score,
        lead_retargeting_score,
        automatic_lead_importing_score
      ].each do |score|
        @_lead_response_score += score
      end

      if @_lead_response_score > total_score
        raise "Score #{@_lead_response_score} is greater than total score #{total_score}"
      end

      @_lead_response_score
    end

    def total_score_in_percentage
      @_total_score_in_percentage ||= score_in_percentage(score, total_score)
    end

    def total_score
      @_total_score ||= SurveyResult::LEAD_RESPONSE_MEASUREMENT_SCORING.values.max +
                        SurveyResult::LEAD_SOURCE_ANALYSIS_SCORING.values.max +
                        SurveyResult::DRIP_CAMPAIGNS_TO_FOLLOWUP_SCORING.values.max +
                        SurveyResult::USE_CRM_SCORING.values.max
    end

    private

    def immediate_response_max_score
      SurveyResult::LEAD_RESPONSE_MEASUREMENT_SCORING.values.max
    end

    def lead_retargeting_max_score
      SurveyResult::DRIP_CAMPAIGNS_TO_FOLLOWUP_SCORING.values.max
    end

    def automatic_lead_importing_max_score
      SurveyResult::USE_CRM_SCORING.values.max
    end

  end

end
