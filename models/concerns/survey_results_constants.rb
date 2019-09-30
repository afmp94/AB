module SurveyResultsConstants

  PAYMENT_STATUS = {
    0 => "Unpaid",
    1 => "Paid by user",
    2 => "Paid by broker",
    3 => "Free",
  }.freeze

  BIO_CURRENT_SCORING = {
    false => 0,
    true => 3,
  }.freeze

  BUYER_TOUCHES_SCORING = {
    "I send them something or touch base with them every day" => 3,
    "At least 3 times per week" => 2,
    "Once a week" => 1,
    "At least monthly" => 0,
    "It depends, whenever they need something" => 0,
  }.freeze

  CONTACTS_GROUPED_SCORING = {
    "Most of my contacts have been grouped" => 3,
    "Just my important contacts have been grouped" => 2,
    "Some contacts are in groups but most are not" => 1,
    "No/Not sure what this is" => 0,
  }.freeze

  CONTACTS_RANKED_SCORING = {
    false => 0,
    true => 3,
  }.freeze

  DAILY_PERSONAL_MARKETING_EFFORT_SCORING = {
    "More than 3 hours" => 3,
    "2 to 3 hours" => 3,
    "1 to 2 hours" => 1,
    "Less than 1 hour" => 0,
  }.freeze

  DAILY_PIPELINE_REVIEW_SCORING = {
    "Daily" => 3,
    "A few times per week" => 2,
    "Weekly" => 1,
    "Every two weeks" => 0,
    "I don't have my sales pipeline documented in one place" => 0,
  }.freeze

  DAILY_TASKS_SET_SCORING = {
    "Yes - I use a CRM and update it daily" => 3,
    "Yes - I use a CRM or app and refer to it multiple times per week" => 2,
    "Yes - I make a written to-do list daily" => 3,
    "Yes - I have a written to-do list and update it periodically" => 1,
    "No - My tasks are in a variety of places" => 0,
    "No - I can handle everything in my head" => 0,
  }.freeze

  DRIP_CAMPAIGNS_TO_FOLLOWUP_SCORING = {
    "Yes" => 3,
    "Some of them, when I can" => 2,
    "No - I have no system" => 0,
    "No - I don't think it is worth it" => 0,
  }.freeze

  FOLLOW_UP_SYSTEM_SCORING = {
    false => 0,
    true => 3,
  }.freeze

  HEADSHOT_CURRENT_SCORING = {
    false => 0,
    true => 3,
  }.freeze

  LEAD_RESPONSE_MEASUREMENT_SCORING = {
    "Always (or faster)" => 3,
    "Most of the time (3 out of 4 times)" => 2,
    "Less than half (2 out of 4 times)" => 0,
    "Not sure (I lose track of them/I don't have a system to track)" => 0,
  }.freeze

  LEAD_SOURCE_ANALYSIS_SCORING = {
    false => 0,
    true => 3,
  }.freeze

  LISTING_PLAN_SCORING = {
    "Yes - And I do an excellent job of getting buy-in and managing client expectations" => 3,
    "Yes - But I could be more prepared" => 1,
    "Yes - But I need to do a better job of communicating boundaries and giving critical feedback" => 1,
    "Sometimes" => 0,
    "No" => 0,
  }.freeze

  LOCAL_SERVICE_LIST_SCORING = {
    false => 0,
    true => 3,
  }.freeze

  MONTHLY_EMAIL_NEWSLETTER_SENT_SCORING = {
    "Yes - Every month like clockwork" => 3,
    "Yes - A few times a year when I have time" => 1,
    "No - I should but I don't have time/don't really know how" => 0,
    "No - I don't think it's valuable to my business" => 0,
    "Other" => 0,
  }.freeze

  MONTHLY_PRINT_SENT_SCORING = {
    "Yes - Monthly" => 3,
    "Yes - A few times a year" => 2,
    "Yes - Once a year" => 1,
    "No - I should but I don't have time/don't really know how" => 0,
    "No - I don't think it's valuable to my business" => 0,
  }.freeze

  NEIGHBORHOOD_FARMING_CARDS_SENT_SCORING = {
    "Yes, always" => 3,
    "Most of the time" => 2,
    "Sometimes" => 0,
    "No, never" => 0,
  }.freeze

  NETWORKING_MEETINGS_SCORING = {
    "Multiple times per week" => 4,
    "About once a week" => 3,
    "Multiple times per month" => 3,
    "About once a month" => 2,
    "Occasionally (a few times a year)" => 1,
    "Rarely" => 0,
    "Never" => 0,
  }.freeze

  ONLINE_PROFILES_CURRENT_SCORING = {
    false => 0,
    true => 3,
  }.freeze

  PAST_CLIENTS_TOUCH_SCORING = {
    "Multiple times per year" => 3,
    "Once a year" => 2,
    "Sometimes - a bit random" => 0,
    "Seldomly" => 0,
    "Almost never" => 0,
  }.freeze

  PRE_MADE_MARKETING_PLAN_SCORING = {
    "Yes - I have excellent marketing materials" => 3,
    "Yes - I have materials but they could be better" => 2,
    "I have some items but they sell me short/I'm missing some elements" => 1,
    "I'm not satisfied with the marketing items I currently have to offer prospects" => 0,
    "No - I don't have print or email marketing items for potential clients" => 0,
  }.freeze

  PROFILE_BROKER_PAGES_CURRENT_SCORING = {
    false => 0,
    true => 3,
  }.freeze

  REFERRAL_SYSTEM_SCORING = {
    false => 0,
    true => 3,
  }.freeze

  REGULAR_SERVICE_REPORTS_SCORING = {
    false => 0,
    true => 3,
  }.freeze

  SELLER_WEEKLY_UPDATE_SCORING = {
    false => 0,
    true => 3,
  }.freeze

  SIZE_OF_DATABASE_SCORING = {
    "Fewer than 10" => 0,
    "10 to 40" => 1,
    "40 to 100" => 2,
    "100 to 300" => 3,
    "More than 300" => 4,
  }.freeze

  SOCIAL_MEDIA_ENGAGEMENT_SCORING = {
    "More than 10 times per month" => 3,
    "Between 6 and 10 times per month" => 3,
    "Less than 5 times per month" => 1,
    "Never - I don't think it's valuable to my business" => 0,
    "Never - I don't know how or have the time" => 0,
  }.freeze

  SYSTEM_FOR_TRANSACTIONS_SCORING = {
    false => 0,
    true => 3,
  }.freeze

  TESTIMONIALS_CURRENT_SCORING = {
    "Always" => 3,
    "Sometimes" => 2,
    "Rarely" => 1,
    "Never" => 0,
  }.freeze

  TRACKING_TOOL_SCORING = {
    "Broker provided solution" => 2,
    "CRM (which I use weekly)" => 4,
    "CRM (which I use monthly)" => 3,
    "CRM (but I rarely use it)" => 1,
    "Phone/email" => 1,
    "Pen and paper" => 1,
    "Don't really have a system" => 0,
    "Other" => 1,
  }.freeze

  USE_CRM_SCORING = {
    "Yes - a CRM" => 3,
    "Yes - I manage them in the Zillow or Trulia app" => 1,
    "No" => 0,
  }.freeze

  WORKLOADS = [
    "More than 60 hours per week",
    "35 to 59 hours per week",
    "20 to 35 hours per week",
    "Less than 20 per week"
  ].freeze

  QUESTIONS = {
    branding: {
      bio_current: "Do you have a current personal bio saved (updated in last 12 months)?",
      headshot_current: "Do you have a current personal headshot saved (updated in last 12 months)?",
      online_profiles_current: "Are your online profiles (Trulia, Zillow, Realtor.com, etc) updated with your current headshot, bio and at least 3 recent testimonials?",
      profile_broker_pages_current: "Does your personal website or broker-provided web page have an updated headshot, bio and at least 3 recent testimonials?",
      testimonials_current: "How often do you solicit testimonials from your satisfied clients after their closing?",
    },
    database: {
      contacts_grouped: "Do you have your database of contacts sorted into groups (e.g. family: friends: past clients: lenders: etc)?",
      contacts_ranked: "Have you ranked or graded all of your contacts to separate out the most valuable to your business?",
      local_service_list: "Do you have an updated: ready-to-go list of local service providers that you could print out: email or refer to?",
      networking_meetings: "How often do you attend local networking events or community functions?",
      tracking_tool: "What do you use most often to keep track of your contacts?",
    },
    relationship_marketing: {
      daily_personal_marketing_effort: "How much time do you spend daily on personal or relationship marketing (promoting yourself through networking: sending out mailings or email newsletters: or personal communication with your database of contacts)?",
      past_clients_touch: "How often do you stay in touch and follow up with your past clients?",
      referral_system: "Do you have a system to track who refers your business?",
      size_of_database: "How many people do you know that could potentially do business with you: or refer you new business?",
    },
    mass_marketing: {
      monthly_email_newsletter_sent: "Do you currently send a monthly email newsletter?",
      monthly_print_sent: "Do you send a print newsletter by mail?",
      neighborhood_farming_cards_sent: "Do you send 'just listed' or 'just sold' cards out to neighborhoods?",
      social_media_engagement: "How often do you post on social media?",
    },
    lead_response: {
      drip_campaigns_to_followup: "Do you put new leads onto an automated drip campaign so you can follow up at regular intervals?",
      lead_response_measurement: "How often do you respond to new incoming leads within 5 minutes?",
      lead_source_analysis: "Do you track where your leads come from and which is the best return on your time spent? ",
      use_crm: "Do your new incoming leads go automatically into a CRM (or other application) so you can track them?",
    },
    prospect_conversion: {
      follow_up_system: "Do you have a system that sends you automatic reminders about which long term prospects you need to follow up with each week?",
      pre_made_marketing_plan: "Do you have prepared: well-designed: customized marketing materials that communicate your value proposition (information about you: your brokerage: your services: and why a potential client should choose you as their agent)?",
    },
    agent: {
      buyer_touches: "How often are you in touch with your typical buyer clients? ",
      listing_plan: "Do you sit down with each new client and present a gameplan: have a conversation about how you do business and what your expectations are: and provide them a rough outline of the next 6-12 months (or the likely duration of the transaction)?",
      regular_service_reports: "Do you currently send regular service reports to your clients?",
      seller_weekly_update: "Do you have a regular time scheduled each week to proactively reach out to and update your seller clients?",
    },
    pipeline: {
      daily_pipeline_review: "How often do you review your entire sales pipeline top to bottom to make sure you're on top of everything?",
      daily_tasks_set: "Do you have a daily task list to keep track of your tasks to follow up with leads and prospects and service your clients?",
      system_for_transactions: "Do you have a system for managing and tracking your prospects: active clients and pending clients?",
    },
  }.freeze

end
