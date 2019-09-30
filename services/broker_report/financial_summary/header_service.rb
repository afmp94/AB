module BrokerReport

  module FinancialSummary

    class HeaderService < BaseService

      def gross_sales_volume
        scope.sum(&:gross_sales_volume)
      end

      def gross_sales_commission
        scope.sum(&:gross_commission)
      end

      def transactions
        scope.sum(&:annual_transaction_goal)
      end

      def about
        if filter_key == "broker_code"
          "broker"
        else
          "office"
        end
      end

    end

  end

end
