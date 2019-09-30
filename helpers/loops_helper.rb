module LoopsHelper

  def dotloop_connection?(user)
    user.integrations.first.present?
  end

  def lead_connected_to_loop?(lead)
    lead.loop.present?
  end

end
