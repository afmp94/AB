class Firebase::BasePushNotifier < ApplicationService

  include Firebase::Support

  delegate :firebase_tokens, to: :receiver, allow_nil: true

  def initialize(model:, receiver:)
    @model    = model
    @receiver = receiver
  end

  def call
    return if firebase_tokens.blank?

    firebase_tokens.each(&method(:send_push))
  end

  private

  attr_reader :model, :receiver

  def send_push(token)
    return unless token&.fcm_token

    fcm.send(token.fcm_token, options(token))
  end

  def options(token)
    token.android? ? android_options : ios_options
  end

  def android_options
    {
      data: {
        title: title,
        body: body
      }.merge(additional_info)
    }
  end

  def ios_options
    {
      notification: {
        title: title,
        text: body
      }
    }.merge(data: additional_info)
  end

end
