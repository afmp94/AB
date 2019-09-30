module Admin
  class CoachingCardsController < Admin::ApplicationController
    # To customize the behavior of this controller,
    # you can overwrite any of the RESTful actions. For example:
    #
    # def index
    #   super
    #   @resources = CoachingCard.
    #     page(params[:page]).
    #     per(10)
    # end

    # Define a custom finder by overriding the `find_resource` method:
    # def find_resource(param)
    #   CoachingCard.find_by!(slug: param)
    # end

    def resource_params
      params["coaching_card"]["locations"] = params["coaching_card"]["locations"].split(" ")
      params.
        require(:coaching_card).
        permit(*dashboard.permitted_attributes, locations: [])
    end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
  end
end
