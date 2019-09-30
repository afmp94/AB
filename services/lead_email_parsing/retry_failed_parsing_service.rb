module LeadEmailParsing

  class RetryFailedParsingService

    def process
      LeadEmail.failed_parsing.find_each do |lead_email|
        LeadEmailProcessingService.new(lead_email).process
      end
    end

  end

end
