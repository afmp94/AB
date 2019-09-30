module Firebase::Support

  def fcm
    @fcm ||= FCM.new(server_key)
  end

  private

  def server_key
    Rails.application.secrets.firebase[:server_key]
  end

end
