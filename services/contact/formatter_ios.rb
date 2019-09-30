class Contact

  class FormatterIOS < ApplicationService

    def initialize(params={})
      @value = params[:value]
      @field = params.fetch(:field, "")
    end

    def call
      format!
    end

    private

    attr_reader :value, :field

    def format!
      case field.to_sym
      when :number
        value.gsub(/[\s\-\(\)]+/, "")
      else
        value
      end
    end

  end

end
