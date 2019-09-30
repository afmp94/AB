module SurveyResults

  class PipelineService < BaseService

    def client_management
      @_client_management ||= survey_result.system_for_transactions
    end

    def client_management_score
      @_client_management_score ||= SurveyResult::SYSTEM_FOR_TRANSACTIONS_SCORING[client_management]
    end

    def daily_pipeline_review
      @_daily_pipeline_review ||= survey_result.daily_pipeline_review
    end

    def daily_pipeline_review_score
      @_daily_pipeline_review_score ||= SurveyResult::DAILY_PIPELINE_REVIEW_SCORING[daily_pipeline_review]
    end

    def daily_pipeline_review_in_percenage
      @_daily_pipeline_review_in_percenage ||= score_in_percentage(
        daily_pipeline_review_score,
        daily_pipeline_review_max_score
      )
    end

    def daily_task_list
      @_daily_task_list ||= survey_result.daily_tasks_set
    end

    def daily_task_list_score
      @_daily_task_list_score ||= SurveyResult::DAILY_TASKS_SET_SCORING[daily_task_list]
    end

    def daily_task_list_in_percenage
      @_daily_task_list_in_percenage ||= score_in_percentage(daily_task_list_score, daily_task_list_max_score)
    end

    def score
      return @_pipeline_score if @_pipeline_score.present?
      @_pipeline_score = 0

      [client_management_score, daily_pipeline_review_score, daily_task_list_score].each do |_score|
        @_pipeline_score += _score
      end

      if @_pipeline_score > total_score
        raise "Count is greater than total_score"
      end

      @_pipeline_score
    end

    def total_score_in_percentage
      @_total_score_in_percentage ||= score_in_percentage(score, total_score)
    end

    def total_score
      @_total_score ||= SurveyResult::SYSTEM_FOR_TRANSACTIONS_SCORING.values.max +
                        SurveyResult::DAILY_PIPELINE_REVIEW_SCORING.values.max +
                        SurveyResult::DAILY_TASKS_SET_SCORING.values.max
    end

    private

    def daily_pipeline_review_max_score
      SurveyResult::DAILY_PIPELINE_REVIEW_SCORING.values.max
    end

    def daily_task_list_max_score
      SurveyResult::DAILY_TASKS_SET_SCORING.values.max
    end

  end

end
