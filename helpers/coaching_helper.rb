module CoachingHelper

  def local_coaching_messages
    current_user.coaching_messages.active.for_location(current_controller_action)
  end

end
