class Contact

  class ImportIOS < ApplicationService

    def initialize(params={})
      @params = params.fetch(:json, [])
      @user   = params[:user]
    end

    def call
      ImportContactsIOSJob.perform_later(serialized_params, user.id)
    end

    private

    attr_reader :user

    def formatted_params
      @formatted_params ||= Contact::ParserIOS.(attributes_collection: params, user: user)
    end

    def serialized_params
      formatted_params.to_json
    end

  end

end
