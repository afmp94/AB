module Cards

  class CoachingService

    attr_reader :user

    def initialize(user)
      @user = user
    end

    def all_cards
      user.coaching_cards
    end

    def branding_coaching_cards
      cards = user.branding_coaching_cards
      displayable_branding_cards(cards)
    end

    def relation_and_database_coaching_cards
      cards = user.relation_and_database_coaching_cards
      displayable_relation_and_database_coaching_cards(cards)
    end

    def personal_and_mass_marketing_coaching_cards
      cards = user.personal_and_mass_marketing_coaching_cards
      displayable_personal_and_mass_marketing_coaching_cards(cards)
    end

    def lead_response_and_conversion_coaching_cards
      cards = user.lead_response_and_conversion_coaching_cards
      displayable_lead_response_and_conversion_coaching_cards(cards)
    end

    def service_management_coaching_cards
      cards = user.service_management_coaching_cards
      displayable_service_management_coaching_cards(cards)
    end

    def self_and_business_management_coaching_cards
      cards = user.self_and_business_management_coaching_cards
      displayable_self_and_business_management_coaching_cards(cards)
    end

    def empty_coaching_cards?
      branding_coaching_cards.blank? &&
        relation_and_database_coaching_cards.blank? &&
        personal_and_mass_marketing_coaching_cards.blank? &&
        lead_response_and_conversion_coaching_cards.blank? &&
        service_management_coaching_cards.blank? &&
        self_and_business_management_coaching_cards.blank?
    end

    private

    def displayable_branding_cards(cards)
      return cards if survey_result.nil? || !survey_result.completed

      @branding_service = SurveyResults::BrandingService.new(survey_result)
      displayble_cards  = []

      cards.each do |card|
        case card.name
        when "get_testimonials"
          if survey_scores.include? @branding_service.testimonials_score
            displayble_cards << card
          end
        when "get_headshot"
          if @branding_service.headshot_score.zero?
            displayble_cards << card
          end
        when "update_bio"
          if @branding_service.bio_score.zero?
            displayble_cards << card
          end
        when "publish_website"
          if @branding_service.website_score.zero?
            displayble_cards << card
          end
        when "update_online_profile"
          if @branding_service.online_profiles_score.zero?
            displayble_cards << card
          end
        end
      end

      displayble_cards
    end

    def displayable_relation_and_database_coaching_cards(cards)
      return cards if survey_result.nil? || !survey_result.completed

      @database_service = SurveyResults::DatabaseService.new(survey_result)
      displayble_cards  = []

      cards.each do |card|
        case card.name
        when "manage_contacts"
          if survey_scores.include? @database_service.contact_management_score
            displayble_cards << card
          end
        when "improve_community"
          if survey_scores.include? @database_service.community_involvement_score
            displayble_cards << card
          end
        when "group_contacts"
          if survey_scores.include? @database_service.grouping_contacts_score
            displayble_cards << card
          end
        when "rank_contacts"
          if @database_service.ranking_contacts_score.zero?
            displayble_cards << card
          end
        when "create_service_provider_list"
          if @database_service.service_providers_score.zero?
            displayble_cards << card
          end
        end
      end

      displayble_cards
    end

    def displayable_personal_and_mass_marketing_coaching_cards(cards)
      return cards if survey_result.nil? || !survey_result.completed

      @relationship_service = SurveyResults::RelationshipMarketingService.new(survey_result)
      @marketing_service    = SurveyResults::MassMarketingService.new(survey_result)
      displayble_cards      = []

      cards.each do |card|
        case card.name
        when "track_referrals"
          if @relationship_service.track_referrals_score.zero?
            displayble_cards << card
          end
        when "increase_contacts"
          if survey_scores.include? @relationship_service.contact_size_score
            displayble_cards << card
          end
        when "manage_past_clients"
          if survey_scores.include? @relationship_service.past_clients_score
            displayble_cards << card
          end
        when "increase_personal_marketing"
          if survey_scores.include? @relationship_service.personal_marketing_score
            displayble_cards << card
          end
        when "increase_email_marketing"
          if survey_scores.include? @marketing_service.email_marketing_score
            displayble_cards << card
          end
        when "increase_print_campaigns"
          if survey_scores.include? @marketing_service.mail_marketing_score
            displayble_cards << card
          end
        when "increase_area_farming"
          if survey_scores.include? @marketing_service.area_framing_score
            displayble_cards << card
          end
        when "increase_social_media"
          if survey_scores.include? @marketing_service.social_media_score
            displayble_cards << card
          end
        end
      end

      displayble_cards
    end

    def displayable_lead_response_and_conversion_coaching_cards(cards)
      return cards if survey_result.nil? || !survey_result.completed

      @lead_response_service = SurveyResults::LeadResponseService.new(survey_result)
      @conversion_service    = SurveyResults::ProspectConversionService.new(survey_result)
      displayble_cards       = []

      cards.each do |card|
        case card.name
        when "respond_immediately"
          if survey_scores.include? @lead_response_service.immediate_response_score
            displayble_cards << card
          end
        when "automatically_import_leads"
          if survey_scores.include? @lead_response_service.automatic_lead_importing_score
            displayble_cards << card
          end
        when "track_lead_source"
          if survey_scores.include? @lead_response_service.lead_source_measurement_score
            displayble_cards << card
          end
        when "increase_lead_retargeting"
          if survey_scores.include? @lead_response_service.lead_retargeting_score
            displayble_cards << card
          end
        when "perform_followup"
          if @conversion_service.follow_up_system_score.zero?
            displayble_cards << card
          end
        when "develop_prospect_materials"
          if @conversion_service.prospect_materials_score.zero?
            displayble_cards << card
          end
        end
      end

      displayble_cards
    end

    def displayable_service_management_coaching_cards(cards)
      return cards if survey_result.nil? || !survey_result.completed

      @agent_service   = SurveyResults::AgentService.new(survey_result)
      displayble_cards = []

      cards.each do |card|
        case card.name
        when "create_listing_prep_plan"
          if survey_scores.include? @agent_service.listing_preparation_plan_score
            displayble_cards << card
          end
        when "create_service_reports"
          if survey_scores.include? @agent_service.service_reports_score
            displayble_cards << card
          end
        when "create_seller_communications"
          if survey_scores.include? @agent_service.seller_communication_score
            displayble_cards << card
          end
        when "create_buyer_communications"
          if survey_scores.include? @agent_service.buyer_communication_score
            displayble_cards << card
          end
        end
      end

      displayble_cards
    end

    def displayable_self_and_business_management_coaching_cards(cards)
      return cards if survey_result.nil? || !survey_result.completed

      @pipeline_service = SurveyResults::PipelineService.new(survey_result)
      displayble_cards  = []

      cards.each do |card|
        case card.name
        when "manage_clients"
          if @pipeline_service.client_management_score.zero?
            displayble_cards << card
          end
        when "manage_pipeline"
          if survey_scores.include? @pipeline_service.daily_pipeline_review_score
            displayble_cards << card
          end
        when "manage_tasks"
          if survey_scores.include? @pipeline_service.daily_task_list_score
            displayble_cards << card
          end
        when "set_goals"
          if user.goals.blank?
            displayble_cards << card
          end
        end
      end

      displayble_cards
    end

    def survey_result
      @survey_result ||= user.survey_result
    end

    def survey_scores
      @scores ||= [0, 1, 2]
    end

  end

end
