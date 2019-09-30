module BrokerReport

  module BusinessDevelopment

    class AnalysisService < BaseService

      def basic_branding
        total_percentage = 0

        scope.all.each do |survey_result|
          total_percentage += SurveyResults::BrandingService.new(survey_result).total_score_in_percentage
        end

        total_percentage / handle_denominator_value(total_agents)
      end

      def contacts_database
        total_percentage = 0

        scope.all.each do |survey_result|
          total_percentage += SurveyResults::DatabaseService.new(survey_result).total_score_in_percentage
        end

        total_percentage / handle_denominator_value(total_agents)
      end

      def personal_marketing
        total_percentage = 0

        scope.all.each do |survey_result|
          total_percentage += SurveyResults::RelationshipMarketingService.new(survey_result).total_score_in_percentage
        end

        total_percentage / handle_denominator_value(total_agents)
      end

      def mass_marketing
        total_percentage = 0

        scope.all.each do |survey_result|
          total_percentage += SurveyResults::MassMarketingService.new(survey_result).total_score_in_percentage
        end

        total_percentage / handle_denominator_value(total_agents)
      end

      def leads_and_conversion
        total_percentage = 0

        scope.all.each do |survey_result|
          total_percentage += SurveyResults::LeadResponseService.new(survey_result).total_score_in_percentage
          total_percentage += SurveyResults::ProspectConversionService.new(survey_result).total_score_in_percentage
        end

        # Multiplying by 2 as we are adding percentage two times
        total_percentage / (handle_denominator_value(total_agents) * 2)
      end

      def servicing_clients
        total_percentage = 0

        scope.all.each do |survey_result|
          total_percentage += SurveyResults::AgentService.new(survey_result).total_score_in_percentage
          total_percentage += SurveyResults::PipelineService.new(survey_result).total_score_in_percentage
        end

        # Multiplying by 2 as we are adding percentage two times
        total_percentage / (handle_denominator_value(total_agents) * 2)
      end

    end

  end

end
