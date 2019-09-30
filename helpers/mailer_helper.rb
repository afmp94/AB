module MailerHelper

  def generate_email_open_tracking_hidden_image(tracking_id, email_address)
    url = "#{root_url}nylasapp-message/tracking/#{Base64.encode64("tracking_id=#{tracking_id}&email_address=#{email_address}")}.png"
    raw("<img src=\"#{url}\" width=\"1\" height=\"1\">")
  end

end
