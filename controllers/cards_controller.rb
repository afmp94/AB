class CardsController < ApplicationController

  def personal_branding
    render
  end

  def business_information
    render
  end

  def sync_email
    render
  end

  def update_business_information
    @user = current_user
    @user.update_attributes!(user_params)

    redirect_to dashboard_path
  end

  def dismiss
    @card = ActionCard.find(params[:card_id])
    @card.mark_as_dismissed_for!(current_user.id)

    if @card.card_type == ActionCard::CARD_TYPES[:new_user]
      @dashboard_presenter = Home::DashboardPresenter.new(current_user)
      render
    else
      render :remind_later
    end
  end

  def open_remind_later_modal
    @card = ActionCard.find(params[:id])
  end

  def remind_later
    @card = ActionCard.find(params[:id])
    @card.remind_later_for!(current_user.id, params[:remind_after_days])
  end

  def user_params
    params.require(:user).permit(
      :id,
      :ab_email_address,
      :agent_percentage_split,
      :address,
      :broker_fee_per_transaction,
      :broker_fee_alternative,
      :broker_fee_alternative_split,
      :city,
      :commission_split_type,
      :company,
      :company_website,
      :contacts_database_storage,
      :country,
      :email,
      :fax_number,
      :first_name,
      :franchise_fee,
      :franchise_fee_per_transaction,
      :last_name,
      :mobile_number,
      :monthly_broker_fees_paid,
      :name,
      :office_number,
      :onboarding_completed,
      :personal_website,
      :real_estate_experience,
      :state,
      :subscribed,
      :time_zone,
      :zip,
      :per_transaction_fee_capped,
      :transaction_fee_cap
    )
  end

end
