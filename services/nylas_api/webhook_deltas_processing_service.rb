class NylasApi::WebhookDeltasProcessingService

  attr_reader :type

  def initialize(deltas)
    @deltas = deltas
  end

  def process
    Rails.logger.info "[NYLAS.webhooks] Processing deltas..."
    @deltas.each do |delta|
      NylasApi::DeltaProcessingService.new(delta).process
    end
  end

end
