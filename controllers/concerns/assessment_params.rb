module AssessmentParams

  def params_list
    [
      info,
      branding,
      contacts,
      personal_marketing,
      mass_marketing,
      lead_generation,
      service_clients,
      goal_setting,
      current_year_progress,
      quick_reaction
    ].reduce([], :concat)
  end

  private

  def quick_reaction
    [
      :quick_reaction_info,
      :quick_reaction_branding,
      :quick_reaction_contacts,
      :quick_reaction_personal_marketing,
      :quick_reaction_mass_marketing,
      :quick_reaction_lead_generation,
      :quick_reaction_service_clients,
      :quick_reaction_goal_setting
    ]
  end

  def info
    [
      :email,
      :first_name,
      :last_name,
      :zip_code,
      :years_experience,
      :workload,
      other_work: []
    ]
  end

  def branding
    [
      :headshot_current,
      :bio_current,
      :profile_broker_pages_current,
      :online_profiles_current,
      :testimonials_current
    ]
  end

  def contacts
    [
      :tracking_tool,
      :networking_meetings,
      :contacts_grouped,
      :contacts_ranked,
      :local_service_list
    ]
  end

  def personal_marketing
    [
      :referral_system,
      :size_of_database,
      :past_clients_touch,
      :daily_personal_marketing_effort
    ]
  end

  def mass_marketing
    [
      :social_media_engagement,
      :monthly_email_newsletter_sent,
      :monthly_print_sent,
      :neighborhood_farming_cards_sent
    ]
  end

  def lead_generation
    [
      :lead_response_measurement,
      :lead_source_analysis,
      :drip_campaigns_to_followup,
      :follow_up_system,
      :use_crm
    ]
  end

  def service_clients
    [
      :pre_made_marketing_plan,
      :listing_plan,
      :regular_service_reports,
      :seller_weekly_update,
      :buyer_touches,
      :system_for_transactions,
      :daily_pipeline_review,
      :daily_tasks_set,
      :survey_token,
      :transaction_fee_cap,
      :years_experience,
      :broker_code,
      :office_code,
      :access_code
    ]
  end

  def goal_setting
    [
      :agent_percentage_split,
      :average_home_price,
      :avg_commission_rate,
      :broker_fee_alternative,
      :broker_fee_alternative_split,
      :broker_fee_per_transaction,
      :commission_split_type,
      :completed,
      :desired_annual_income,
      :est_business_expenses,
      :feedback,
      :feedback_score,
      :franchise_fee,
      :franchise_fee_per_transaction,
      :monthly_broker_fees_paid,
      :network_id,
      :next_year_plans,
      :past_year_income,
      :past_year_total_transaction,
      :payment_status,
      :pays_monthly_broker_fee,
      :per_transaction_fee_capped,
      :platform,
      :promotion_code,
      :referer
    ]
  end

  def current_year_progress
    [
      :current_ytd_client_count,
      :current_ytd_income,
      :current_ytd_lead_count
    ]
  end

end
