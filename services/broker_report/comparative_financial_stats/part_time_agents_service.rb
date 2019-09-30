module BrokerReport

  module ComparativeFinancialStats

    class PartTimeAgentsService < BaseAgentsService

      def income_after_expenses
        total_income(part_time_agents_scope) / handle_denominator_value(total_part_time_agents)
      end

      def avg_number_of_transactions
        total_number_of_transactions(part_time_agents_scope) / handle_denominator_value(total_part_time_agents)
      end

      def avg_home_sales_price
        total_home_sales_price(part_time_agents_scope) / handle_denominator_value(total_part_time_agents)
      end

      private

      def part_time_agents_scope
        scope.where(workload: [SurveyResult::WORKLOADS[2], SurveyResult::WORKLOADS[3]])
      end

      def total_part_time_agents
        part_time_agents_scope.count
      end

    end

  end

end
