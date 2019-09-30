module SurveyResults

  class DatabaseService < BaseService

    def contact_management
      @_contact_management ||= survey_result.tracking_tool
    end

    def contact_management_score
      @_contact_management_score ||= SurveyResult::TRACKING_TOOL_SCORING[contact_management]
    end

    def contact_management_in_percentage
      @_contact_management_in_percentage ||= score_in_percentage(contact_management_score, contact_management_max_score)
    end

    def community_involvement
      @_community_involvement ||= survey_result.networking_meetings
    end

    def community_involvement_score
      @_community_involvement_score ||= SurveyResult::NETWORKING_MEETINGS_SCORING[community_involvement]
    end

    def community_involvement_in_percentage
      @_community_involvement_in_percentage ||= score_in_percentage(
        community_involvement_score,
        community_involvement_max_score
      )
    end

    def grouping_contacts
      @_grouping_contacts ||= survey_result.contacts_grouped
    end

    def grouping_contacts_score
      @_grouping_contacts_score ||= SurveyResult::CONTACTS_GROUPED_SCORING[grouping_contacts]
    end

    def grouping_contacts_in_percentage
      @_grouping_contacts_in_percentage ||= score_in_percentage(grouping_contacts_score, grouping_contacts_max_score)
    end

    def ranking_contacts
      @_ranking_contacts ||= survey_result.contacts_ranked
    end

    def ranking_contacts_score
      @ranking_contacts_score ||= SurveyResult::CONTACTS_RANKED_SCORING[ranking_contacts]
    end

    def service_providers
      @_service_providers ||= survey_result.local_service_list
    end

    def service_providers_score
      @_service_providers_score ||= SurveyResult::LOCAL_SERVICE_LIST_SCORING[service_providers]
    end

    def score
      return @_database_score if @_database_score.present?
      @_database_score = 0

      [contact_management_score, community_involvement_score, grouping_contacts_score,
       ranking_contacts_score, service_providers_score].each do |_score|
        @_database_score += _score
      end

      if @_database_score > total_score
        raise "Score #{@_database_score} is greater than total score #{total_score}"
      end

      @_database_score
    end

    def total_score_in_percentage
      @_total_score_in_percentage ||= score_in_percentage(score, total_score)
    end

    def total_score
      @_total_score ||= SurveyResult::TRACKING_TOOL_SCORING.values.max +
                        SurveyResult::NETWORKING_MEETINGS_SCORING.values.max +
                        SurveyResult::CONTACTS_GROUPED_SCORING.values.max +
                        SurveyResult::CONTACTS_RANKED_SCORING.values.max +
                        SurveyResult::LOCAL_SERVICE_LIST_SCORING.values.max
    end

    private

    def contact_management_max_score
      SurveyResult::TRACKING_TOOL_SCORING.values.max
    end

    def community_involvement_max_score
      SurveyResult::NETWORKING_MEETINGS_SCORING.values.max
    end

    def grouping_contacts_max_score
      SurveyResult::CONTACTS_GROUPED_SCORING.values.max
    end

  end

end
