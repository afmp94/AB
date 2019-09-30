class DotloopService::Profile

  def fetch_all(set_dotloop_client)
    profiles = []
    dotloop_profiles = set_dotloop_client.Profile.all
    dotloop_profiles.each do |profile|
      if profile.deactivated == nil
        profiles << profile
      end
    end
    profiles
  end

end
