module EnvironmentBannerHelper

  def current_branch
    if git_available?
      `git rev-parse --abbrev-ref HEAD`.chomp
    else
      Rails.application.secrets.url_with_port
    end
  end

  def current_sha
    if git_available?
      `git log -1 --abbrev-commit --oneline | cut -d ' ' -f 1`
    else
      ENV.fetch("CURRENT_SHA", "")
    end
  end

  def git_available?
    to_dev_null = "> /dev/null 2>&1"
    system("which git #{to_dev_null} && git rev-parse --git-dir #{to_dev_null}")
  end

  def display_variant
    if browser.ua.match?(Rails.application.secrets.ios_user_agent)
      ":iOS app"
    elsif browser.ua.match?(Rails.application.secrets.android_user_agent)
      ":android app"
    elsif browser.device.mobile? || browser.device.tablet?
      ":phone"
    else
      ":desktop"
    end
  end

end
