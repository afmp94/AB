module BrokerReport

  module ComparativeFinancialStats

    class BaseAgentsService < BaseService

      def income_after_expenses
        raise "Should be implemented by sub class"
      end

      def avg_number_of_transactions
        raise "Should be implemented by sub class"
      end

      def avg_home_sales_price
        raise "Should be implemented by sub class"
      end

      private

      def total_income(overriden_scope=nil)
        if overriden_scope.nil?
          scope.sum(:desired_annual_income).round(2)
        else
          overriden_scope.sum(:desired_annual_income).round(2)
        end
      end

      def total_number_of_transactions(overriden_scope=nil)
        if overriden_scope.nil?
          scope.sum(&:estimated_number_of_sides).round(2)
        else
          overriden_scope.sum(&:estimated_number_of_sides).round(2)
        end
      end

      def total_home_sales_price(overriden_scope=nil)
        if overriden_scope.nil?
          scope.sum(:average_home_price).round(2)
        else
          overriden_scope.sum(:average_home_price).round(2)
        end
      end

    end

  end

end
