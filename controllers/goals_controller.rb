class GoalsController < ApplicationController

  before_action :load_goal, only: [
    :activities_edit,
    :activities_update,
    :destroy,
    :edit,
    :show,
    :update
  ]

  def index
    @goals = current_user.goals
  end

  def show
    render
  end

  def new
    @goal = current_user.goals.build
    @commission_carrier = CommissionCarrier.new(@goal.user)
    session[:referring_page] = request.referer || @goal
  end

  def edit
    @commission_carrier = CommissionCarrier.new(@goal.user)
    session[:referring_page] = request.referer || edit_goal_path(@goal)
  end

  def activities_edit
    render
  end

  def activities_update
    goal_params = sanitized_goal_params
    session[:referring_page] = request.referer || @goal

    unless total_weekly_effort_valid?(goal_params)
      redirect_to(
        activities_edit_goal_path(@goal),
        alert: "Weekly effort from Call, Notes and Visits doesn't match Total Weekly Effort."
      ) && return
    end

    if @goal.update_attributes(goal_params)
      current_user.mark_initial_setup_done!
      redirect_to(
        session[:referring_page],
        notice: "Goal activities successfully updated."
      )
    else
      flash.now[:danger] = "Please check your entry and try again."
      render action: "activities_edit"
    end
  end

  def create
    @goal = current_user.goals.build(sanitized_goal_params)

    respond_to do |format|
      if @goal.save
        current_user.mark_initial_setup_done! unless current_user.initial_setup?
        format.html do
          redirect_to(
            session[:referring_page] || dashboard_path,
            notice: "Goal was successfully created."
          )
        end
        format.json { render action: "show", status: :created, location: @goal }
      else
        format.html do
          @commission_carrier = CommissionCarrier.new(@goal.user)
          flash.now[:danger] = "Please check your entry and try again."
          render :new
        end
        format.json { render json: @goal.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @goal.update_attributes(sanitized_goal_params)
      redirect_to(
        session[:referring_page] || dashboard_path,
        notice: "Goal was successfully updated."
      )
    else
      @commission_carrier = CommissionCarrier.new(@goal.user)
      flash.now[:danger] = "Please check your entry and try again."
      render :new
    end
  end

  def update_goal_from_wizard
    load_goal

    if @goal.update!(sanitized_goal_params)
      render json: @goal
    else
      Rails.logger.error "[GOALS] Cannot update goal record"
      render(json: @goal.errors, status: :unprocessable_entity)
    end
  end

  def destroy
    @goal.destroy
    respond_to do |format|
      format.html { redirect_to goals_url }
      format.json { head :no_content }
    end
  end

  def goals_wizard
    @goals_wizard_facade = GoalsWizardFacade.new(current_user)
  end

  private

  def load_goal
    @goal = current_user.goals.find(params[:id])
  end

  def total_weekly_effort_valid?(activity_params)
    activity_params[:total_weekly_effort].to_i == (
      activity_params[:calls_required_wkly].to_i +
      activity_params[:note_required_wkly].to_i +
      activity_params[:visits_required_wkly].to_i
    )
  end

  def sanitized_goal_params
    unsanitized_goal_params = params.require(:goal).permit(
      :id,
      :annual_transaction_goal,
      :avg_commission_rate,
      :avg_price_in_area,
      :calls_required_wkly,
      :contacts_need_per_month,
      :contacts_to_generate_one_referral,
      :daily_calls_goal,
      :daily_notes_goal,
      :daily_visits_goal,
      :desired_annual_income,
      :est_business_expenses,
      :gross_commission_goal,
      :gross_sales_vol_required,
      :monthly_transaction_goal,
      :note_required_wkly,
      :portion_of_agent_split,
      :qtrly_transaction_goal,
      :referrals_for_one_close,
      :total_weekly_effort,
      :visits_required_wkly,
      :year,
      :agent_percentage_split,
      :broker_fee_alternative,
      :broker_fee_per_transaction,
      :commission_split_type,
      :franchise_fee,
      :franchise_fee_per_transaction,
      :monthly_broker_fees_paid,
      :per_transaction_fee_capped,
      :transaction_fee_cap,
      :broker_fee_alternative_split,
    )

    Goal.scrub_goal_price_fields unsanitized_goal_params
  end

end
