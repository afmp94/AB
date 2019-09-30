class ApplicationService

  def self.call(params={})
    new(params).()
  end

  def initialize(params={})
    @params = params
  end

  private

  attr_accessor :params

end
