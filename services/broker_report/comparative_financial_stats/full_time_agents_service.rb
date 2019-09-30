module BrokerReport

  module ComparativeFinancialStats

    class FullTimeAgentsService < BaseAgentsService

      def income_after_expenses
        total_income(full_time_agents_scope) / handle_denominator_value(total_full_time_agents)
      end

      def avg_number_of_transactions
        total_number_of_transactions(full_time_agents_scope) / handle_denominator_value(total_full_time_agents)
      end

      def avg_home_sales_price
        total_home_sales_price(full_time_agents_scope) / handle_denominator_value(total_full_time_agents)
      end

      private

      def full_time_agents_scope
        scope.where(workload: [SurveyResult::WORKLOADS[0], SurveyResult::WORKLOADS[1]])
      end

      def total_full_time_agents
        full_time_agents_scope.count
      end

    end

  end

end
