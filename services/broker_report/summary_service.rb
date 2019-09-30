module BrokerReport

  class SummaryService

    attr_accessor :broker_code, :office_code

    def initialize(broker_code=nil, office_code=nil)
      @broker_code = broker_code
      @office_code = office_code
    end

    def prepared_for
      "#{broker_code}/#{office_code}"
    end

    def date
      SurveyResult.where(broker_code: broker_code, office_code: office_code).last.created_at
    end

  end

end
