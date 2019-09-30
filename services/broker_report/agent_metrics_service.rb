module BrokerReport

  class AgentMetricsService < BaseService

    def invitations_sent
      "???"
    end

    def assessments_completed
      scope.pluck(:completed).count
    end

    def percent_completed
      # invitations_sent / assessmens_completed

      "???"
    end

    def name
      filter_value
    end

  end

end
