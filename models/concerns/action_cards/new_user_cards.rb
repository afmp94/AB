module ActionCards::NewUserCards

  NEW_USER_CARDS = [
    {
      order: 1,
      header: "Build relationships",
      icon: "upload",
      description: "To get started, you need some Contacts!",
      action: "Import",
      link:  "new_upload_contact_path"
    },
    {
      order: 2,
      header: "Start with Personal Branding",
      icon: "file image outline",
      description: "Communicate with confidence everytime.",
      action: "Upload",
      link: "personal_branding_cards_path"
    },
    {
      order: 3,
      header: "Get Focused",
      icon: "bullseye",
      description: "Make your Big Hairy Goal a reality!",
      action: "Set Goals",
      link:  "goals_path"
    },
    {
      order: 4,
      header: "Confirm Email",
      icon: "check",
      description: "To use all our features, be sure to verify your email sent to you. Check your email or click here to resend confirmation and then check your email.",
      action: "Resend Now",
      link:  "send_email_confirmation_notification_path"
    },
    {
      order: 5,
      header: "Be Professional Everytime!",
      icon: "id card outline",
      description: "Ensure your professional details are shared every time.",
      action: "Start Now",
      link: "business_information_cards_path"
    },
    {
      order: 6,
      header: "Build Relationships",
      icon: "sort content ascending",
      description: "Prioritize your relationships (A+, A, B, etc) and we will remind you to stay in touch.",
      action: "Rank Now!",
      link: "rank_contact_path"
    },
    {
      order: 7,
      header: "Connect Communications",
      icon: "linkify",
      description: "Quick & easy access to view, send and recieve emails for contacts, leads or clients.",
      action: "Connect Now!",
      link:  "sync_email_cards_path"
    },
    {
      order: 8,
      header: "Add Clients",
      icon: "handshake",
      description: "Start managing your current business now!",
      action: "Add Clients",
      link: "new_lead_path"
    },
    {
      order: 9,
      header: "Get things done",
      icon: "checkmark box",
      description: "Clear you mind! Add tasks to a lead or client, then we then remind you!",
      action: "Add Task",
      link:  "new_task_path"
    },
    {
      order: 10,
      header: "Kickstart your Marketing",
      icon: "open envelope outline",
      description:  "Send quick email blasts in just minutes.",
      action: "Send Now",
      link: "email_campaigns_path(EmailCampaign.new, campaign_type: EmailCampaign::CAMPAIGN_TYPES[:basic])"
    },
    {
      order: 11,
      header: "Agent Assessment",
      icon: "dashboard",
      description: "Get clarity and motivation in just 15 minutes.",
      action: "Take Tour",
      link:  "assessment_path"
    },
  ].freeze

end
