class Api::V1::FirebaseTokens::Update < ApplicationService

  delegate :firebase_tokens, to: :user, allow_nil: true

  def initialize(user:, token:, device:, android: nil)
    @user = user
    @token = token
    @device = device
    @android = android
  end

  def call
    return failure unless token && user && device

    firebase_token.update(fcm_token: token, device_type: device_type)

    success
  end

  private

  attr_reader :user, :token, :device, :android

  def firebase_token
    @firebase_token ||= firebase_tokens.find_or_initialize_by(device_id: device)
  end

  def failure
    :bad_request
  end

  def device_type
    android ? :android : :ios
  end

  def success
    :ok
  end

end
