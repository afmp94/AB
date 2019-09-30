module SurveyResults

  class AgentService < BaseService

    def listing_preparation_plan
      @_listing_preparation_plan ||= survey_result.listing_plan
    end

    def listing_preparation_plan_score
      @_listing_preparation_plan_score ||= SurveyResult::LISTING_PLAN_SCORING[listing_preparation_plan]
    end

    def listing_preparation_plan_in_percentage
      @_listing_preparation_plan_in_percentage ||= score_in_percentage(
        listing_preparation_plan_score,
        listing_preparation_plan_max_score
      )
    end

    def service_reports
      @_service_reports ||= survey_result.regular_service_reports
    end

    def service_reports_score
      @_service_reports_score ||= SurveyResult::REGULAR_SERVICE_REPORTS_SCORING[service_reports]
    end

    def seller_communication
      @_seller_communication ||= survey_result.seller_weekly_update
    end

    def seller_communication_score
      @_seller_communication_score ||= SurveyResult::SELLER_WEEKLY_UPDATE_SCORING[seller_communication]
    end

    def buyer_communication
      @_buyer_communication ||= survey_result.buyer_touches
    end

    def buyer_communication_score
      @_buyer_communication_score ||= SurveyResult::BUYER_TOUCHES_SCORING[buyer_communication]
    end

    def buyer_communication_in_percentage
      @_buyer_communication_in_percentage ||= score_in_percentage(
        buyer_communication_score,
        buyer_communication_max_score
      )
    end

    def score
      return @_agent_score if @_agent_score.present?
      @_agent_score = 0

      [
        listing_preparation_plan_score,
        service_reports_score,
        seller_communication_score,
        buyer_communication_score
      ].each do |_score|
        @_agent_score += _score
      end

      if @_agent_score > total_score
        raise "Score #{@_agent_score} is greater than total score #{total_score}"
      end

      @_agent_score
    end

    def total_score_in_percentage
      @_total_score_in_percentage ||= score_in_percentage(score, total_score)
    end

    def total_score
      @_total_score ||= SurveyResult::LISTING_PLAN_SCORING.values.max +
                        SurveyResult::REGULAR_SERVICE_REPORTS_SCORING.values.max +
                        SurveyResult::SELLER_WEEKLY_UPDATE_SCORING.values.max +
                        SurveyResult::BUYER_TOUCHES_SCORING.values.max
    end

    private

    def listing_preparation_plan_max_score
      SurveyResult::LISTING_PLAN_SCORING.values.max
    end

    def buyer_communication_max_score
      SurveyResult::BUYER_TOUCHES_SCORING.values.max
    end

  end

end
