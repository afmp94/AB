class Public::ContactsController < ApplicationController

  skip_before_action :authenticate_user!

  def unsubscribe
    @contact = Contact.find_by(unsubscribed: false, subscription_token: params[:subscription_token])
    @contact.update!(unsubscribed: true) if @contact.present?

    render layout: false
  end

end
