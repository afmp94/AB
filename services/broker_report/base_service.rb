module BrokerReport

  class BaseService

    attr_reader :filter_key, :filter_value

    def initialize(filter_key, filter_value)
      @filter_key   = filter_key
      @filter_value = filter_value
    end

    def self.wrap(broker_code=nil, office_code=nil)
      filters = []

      filters << new("broker_code", broker_code) if broker_code.present?
      filters << new("office_code", office_code) if office_code.present?

      filters
    end

    def name
      filter_value
    end

    def total_agents
      scope.count
    end

    private

    def scope
      SurveyResult.where("#{filter_key} = ? ", filter_value)
    end

    def handle_denominator_value(denominator_value)
      denominator_value.nonzero? || 1
    end

  end

end
