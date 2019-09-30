class DotloopService::Template

  def fetch_all(dotloop_client, ids)
    templates = []
    ids.each do |id|
      templates << get_template(dotloop_client, id)
    end
    templates
  end

  def get_template(dotloop_client, profile_id)
    result = HTTParty.get("https://api-gateway.dotloop.com/public/v2/profile/#{profile_id}/loop-template",
                          headers:
                          {
                            "Content-Type" => "application/json",
                            "Authorization" => "Bearer #{dotloop_client.access_token}"
                          })
    result.parsed_response["data"]
  end

  def fetch_all_loops(dotloop_client, ids)
    loop_templates = dotloop_client.Loop.all(profile_id: ids.first)
    present_loops = Loop.all.map(&:loop_id)
    loops = loop_templates.flatten.delete_if { |x| present_loops.include? x.id }
    loops
  end

end
