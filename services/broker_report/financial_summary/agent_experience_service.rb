module BrokerReport

  module FinancialSummary

    class AgentExperienceService < BaseService

      attr_reader :filter_key, :filter_value, :experience_slab

      def initialize(filter_key, filter_value, experience_slab)
        @filter_key      = filter_key
        @filter_value    = filter_value
        @experience_slab = experience_slab
      end

      def self.wrap(broker_code=nil, office_code=nil)
        broker_filters = []
        office_filters = []

        [:newbies, :going_pro, :professional, :seasoned_professional].each do |experience|
          broker_filters << new("broker_code", broker_code, experience) if broker_code.present?
          office_filters << new("office_code", office_code, experience) if office_code.present?
        end

        [broker_filters, office_filters]
      end

      def experience
        case @experience_slab
        when :newbies
          "Newbie (0 - 2 years)"
        when :going_pro
          "Going Pro (3 - 7 years)"
        when :professional
          "Professional (7 - 15 years)"
        when :seasoned_professional
          "Professional (15 or more years)"
        end
      end

      def number_of_agents
        experience_scope.count
      end

      def average_income
        experience_scope.sum(:desired_annual_income) / handle_denominator_value(number_of_agents)
      end

      def avg_number_of_transactions
        experience_scope.sum(&:estimated_number_of_sides) / handle_denominator_value(number_of_agents)
      end

      def average_home_sale
        experience_scope.sum(:average_home_price) / handle_denominator_value(number_of_agents)
      end

      def top_priorities_seeking
        branding               = []
        database               = []
        relationship_marketing = []
        mass_marketing         = []
        lead_response          = []
        prospect_conversion    = []
        service                = []
        pipeline               = []

        experience_scope.each do |survey_result|
          branding.push(SurveyResults::BrandingService.new(survey_result).total_score_in_percentage)
          database.push(SurveyResults::DatabaseService.new(survey_result).total_score_in_percentage)
          relationship_marketing.push(
            SurveyResults::RelationshipMarketingService.new(survey_result).total_score_in_percentage
          )
          mass_marketing.push(SurveyResults::MassMarketingService.new(survey_result).total_score_in_percentage)
          lead_response.push(SurveyResults::LeadResponseService.new(survey_result).total_score_in_percentage)
          prospect_conversion.push(
            SurveyResults::ProspectConversionService.new(survey_result).total_score_in_percentage
          )
          service.push(SurveyResults::AgentService.new(survey_result).total_score_in_percentage)
          pipeline.push(SurveyResults::PipelineService.new(survey_result).total_score_in_percentage)
        end

        category_avg_score = {
          "Branding": handle_category_scores(branding),
          "Database": handle_category_scores(database),
          "Relationship service": handle_category_scores(relationship_marketing),
          "Mass marketing": handle_category_scores(mass_marketing),
          "Lead response": handle_category_scores(lead_response),
          "Prospect conversion": handle_category_scores(prospect_conversion),
          "Service": handle_category_scores(service),
          "Pipeline": handle_category_scores(pipeline)
        }

        if category_avg_score.values.any?(&:nonzero?)
          category_avg_score.min_by(2) { |_key, value| value }.map(&:first)
        else
          ["-"]
        end
      end

      def about
        if filter_key == "broker_code"
          "broker"
        else
          "office"
        end
      end

      private

      def experience_scope
        case @experience_slab
        when :newbies
          scope.where("years_experience <= ?", 2)
        when :going_pro
          scope.where("years_experience > ? AND years_experience < ? ", 2, 7)
        when :professional
          scope.where("years_experience > ? AND years_experience < ? ", 7, 15)
        when :seasoned_professional
          scope.where("years_experience > ?", 15)
        end
      end

      def handle_category_scores(category_scores)
        if category_scores.empty?
          0
        else
          category_scores.sum / category_scores.size
        end
      end

    end

  end

end
