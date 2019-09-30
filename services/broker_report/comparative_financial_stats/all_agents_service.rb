module BrokerReport

  module ComparativeFinancialStats

    class AllAgentsService < BaseAgentsService

      def income_after_expenses
        total_income / handle_denominator_value(total_agents)
      end

      def avg_number_of_transactions
        total_number_of_transactions / handle_denominator_value(total_agents)
      end

      def avg_home_sales_price
        total_home_sales_price / handle_denominator_value(total_agents)
      end

    end

  end

end
