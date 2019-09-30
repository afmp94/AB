module UserCreationControllerCallbacksHelper

  private

  def after_user_creation_callbacks(user)
    @checkout = build_checkout(user)
    @checkout.fulfill

    MailchimpApi::UpdateMemberListService.delay.process_all_lists(user.email)
    OrganizationMember.activate_new_member!(user) if user.agent_token.present?
  end

  def build_checkout(user)
    plan = Plan.find_by(sku: "standard")
    plan.checkouts.build(
      user: user,
      email: user.email
    )
  end

end
