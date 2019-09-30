class SmsMessages::OutgoingMessagesHandler < ApplicationService

  include ActionView::Helpers::NumberHelper

  def initialize(params:, user:)
    @params = params
    @user   = user
  end

  def call
    return if user.twilio_phone_number.blank? || !to

    to.map(&method(:unsent_messages)).compact
  end

  private

  attr_reader :params, :user

  def to
    @to ||= params[:phones]
  end

  def unsent_messages(phone_number)
    formatted_phone(phone_number) unless send_and_create_message(phone_number)
  end

  def formatted_phone(phone_number)
    number_to_phone(phone_number)
  end

  def image
    Image.find_by(id: params[:image_id])
  end

  def send_and_create_message(phone_number)
    SmsMessages::SendAndCreate.call(
      body: params[:body],
      image: image,
      user: user,
      phone_number: phone_number
    )
  end

end
