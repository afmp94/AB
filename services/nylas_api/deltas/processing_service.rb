class NylasApi::Deltas::ProcessingService

  attr_accessor :delta

  def initialize(delta)
    @delta = delta
  end

  def process
    case delta.object
    when "message"
      NylasApi::Deltas::MessageDeltaParser.new(delta).parse
    end
  end

end
