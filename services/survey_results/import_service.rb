module SurveyResults

  class ImportService

    def initialize(survey_result_id)
      @survey_result_id = survey_result_id
    end

    def process
      if survey_result.present? && !survey_result.imported?
        user = survey_result.user

        ActiveRecord::Base.transaction do
          if !user.special_type?
            if user.goals.empty?
              Goal.create(user_id: user.id)
            end

            user.goals.each do |user_goal|
              goal = set_goal_attributes(user_goal)
              goal.save!
            end

            user = set_user_attributes(user)
            user.save!
          end

          survey_result.update!(imported: true)
        end
      end
    end

    private

    def survey_result
      @survey_result ||= SurveyResult.find(@survey_result_id)
    end

    def set_goal_attributes(goal)
      goal.gross_commission_goal             = survey_result.gross_commission
      goal.monthly_transaction_goal          = survey_result.monthly_transaction_goal
      goal.qtrly_transaction_goal            = survey_result.quarterly_transaction_goal
      goal.total_weekly_effort               = survey_result.suggested_total_weekly_effort
      goal.avg_price_in_area                 = survey_result.average_home_price
      goal.avg_commission_rate               = survey_result.avg_commission_rate
      goal.desired_annual_income             = survey_result.desired_annual_income
      goal.est_business_expenses             = survey_result.est_business_expenses
      goal.est_business_expenses             = survey_result.est_business_expenses

      goal.daily_calls_goal                  = survey_result.suggested_calls_needed_per_day
      goal.daily_notes_goal                  = survey_result.suggested_note_required_per_day
      goal.daily_visits_goal                 = survey_result.suggested_visits_required_per_day

      goal.calls_required_wkly               = survey_result.suggested_calls_needed_per_week
      goal.note_required_wkly                = survey_result.suggested_note_required_per_week
      goal.visits_required_wkly              = survey_result.suggested_visits_required_per_week

      goal.gross_sales_vol_required          = survey_result.gross_sales_volume
      goal.contacts_to_generate_one_referral = survey_result.referrals_needed_per_month
      goal.annual_transaction_goal           = survey_result.annual_transaction_goal
      goal.agent_percentage_split            = survey_result.agent_percentage_split
      goal.broker_fee_alternative            = survey_result.broker_fee_alternative
      goal.broker_fee_alternative_split      = survey_result.broker_fee_alternative_split
      goal.broker_fee_per_transaction        = survey_result.broker_fee_per_transaction
      goal.commission_split_type             = survey_result.commission_split_type
      goal.franchise_fee                     = survey_result.franchise_fee
      goal.franchise_fee_per_transaction     = survey_result.franchise_fee_per_transaction
      goal.monthly_broker_fees_paid          = survey_result.monthly_broker_fees_paid
      goal.transaction_fee_cap               = survey_result.transaction_fee_cap
      goal.per_transaction_fee_capped        = survey_result.per_transaction_fee_capped

      goal
    end

    def set_user_attributes(user)
      user.annual_broker_fees_paid       = survey_result.monthly_broker_fees_paid
      user.agent_percentage_split        = survey_result.agent_percentage_split
      user.broker_fee_alternative_split  = survey_result.broker_fee_alternative_split
      user.broker_fee_alternative        = survey_result.broker_fee_alternative
      user.broker_fee_per_transaction    = survey_result.broker_fee_per_transaction
      user.commission_split_type         = survey_result.commission_split_type
      user.franchise_fee                 = survey_result.franchise_fee
      user.per_transaction_fee_capped    = survey_result.per_transaction_fee_capped
      user.transaction_fee_cap           = survey_result.transaction_fee_cap
      user.zip                           = survey_result.zip_code
      user.real_estate_experience        = survey_result.years_experience
      user.broker_percentage_split       = (100 - survey_result.agent_percentage_split)&.round
      user.monthly_broker_fees_paid      = survey_result.monthly_broker_fees_paid

      if survey_result.monthly_broker_fees_paid
        user.annual_broker_fees_paid = (survey_result.monthly_broker_fees_paid * 12)
      end

      user
    end

  end

end
