class SmsMessages::IncomingMessagesHandler < ApplicationService

  include ActionView::Helpers::NumberHelper

  def initialize(params:)
    @params = params
  end

  def call
    user = TwilioPhoneNumber.find_by(twilio_number: params[:To])&.user

    contact = user&.contact_phone_numbers&.find_by(number: from_number_permutations)&.owner

    create_sms_message(user, contact)

    broadcast_to_contact_page

    send_push_notification
  end

  private

  def sms_message(user=nil, contact=nil)
    @sms_message ||= SmsMessage.create!(create_params(user, contact))
  end

  def number_without_plus
    params[:From].delete("+")
  end

  def number_without_country_code
    params[:From].delete("+1")
  end

  def from_number_permutations
    # Does not currently handle "(860) 5755306", "(860) 575 5306"
    [
      params[:From],
      number_without_country_code,
      number_without_plus,
      number_to_phone(params[:From], area_code: true).to_s,
      number_to_phone(number_without_country_code, area_code: true).to_s,
      number_to_phone(number_without_plus, area_code: true).to_s
    ]
  end

  def send_push_notification
    SmsMessages::SendPushNotification.call(model: sms_message, receiver: sms_message.user)
  end

  def broadcast_to_contact_page
    SmsMessages::BroadcastMessage.call(message: sms_message)
  end

  def mms_images
    return if received_file_urls.blank?

    @mms_images ||= received_file_urls.map(&method(:create_image))
  end

  def create_image(url)
    Image.create(remote_file_url: url)
  end

  def received_file_urls
    @received_file_url ||= params.select(&method(:media_file_parameter?)).values
  end

  def media_file_parameter?(key, _value)
    key.to_s.match(/^MediaUrl\d+/)
  end

  def create_params(user, contact)
    {
      user: user,
      contact: contact,
      sid: params[:MessageSid],
      body: params[:Body],
      to: params[:To],
      from: params[:From],
      incoming: true
    }.tap do |parameters|
      return parameters.merge(images: mms_images) if mms_images.present?
    end
  end

  alias_method :create_sms_message, :sms_message

end
