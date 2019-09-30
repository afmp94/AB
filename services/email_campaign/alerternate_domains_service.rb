class EmailCampaign::AlerternateDomainsService

  attr_reader :user_email

  MAIN_DOMAIN = "mg.agentbrightapp.com".freeze

  DOMAINS = %w(
    gmail.com
    yahoo.com
    hotmail.com
    outlook.com
    aol.com
    mac.com
    mac.me
    rocketmail.com
    ymail.com
  ).freeze

  def initialize(user_email)
    @user_email = user_email
  end

  def fetch
    if DOMAINS.any? { |domain| user_email.include? domain }
      append_main_domain
    end
  end

  private

  def append_main_domain
    "#{user_email}.#{MAIN_DOMAIN}"
  end

end
