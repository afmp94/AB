module BrokerReport

  module AgentProfile

    class StatisticsService < BaseService

      def years_of_experience
        scope.sum(:years_experience) / handle_denominator_value(total_agents)
      end

      def percent_full_time
        (full_time_agents_scope.count * 100) / handle_denominator_value(total_agents)
      end

      def average_gross_sales_commission
        scope.sum(:desired_annual_income) / handle_denominator_value(total_agents)
      end

      def average_number_of_transactions
        scope.sum(&:estimated_number_of_sides) / handle_denominator_value(total_agents)
      end

      private

      def full_time_agents_scope
        scope.where(workload: [SurveyResult::WORKLOADS[0], SurveyResult::WORKLOADS[1]])
      end

    end

  end

end
