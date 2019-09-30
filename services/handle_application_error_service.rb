class HandleApplicationErrorService

  attr_reader :appliciton_error, :notify_admin

  def initialize(error, notify_admin=false)
    @appliciton_error = error
    @notify_admin     = notify_admin
  end

  def process
    error_message  = "ApplicationError => #{@appliciton_error.class}: #{@appliciton_error.message}"
    error_metadata =  if @appliciton_error.respond_to?(:raw_body)
                        @appliciton_error.raw_body
                      end

    Rails.logger.info error_message

    Honeybadger.notify(
      error_message: error_message,
      error_class: @appliciton_error.class,
      parameters: error_metadata
    )

    if notify_admin
      AdminMailer.notify_application_error(error_message, error_metadata).deliver
    end
  end

end
