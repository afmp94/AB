module Admin

  class PlansController < Admin::ApplicationController
    # To customize the behavior of this controller,
    # you can overwrite any of the RESTful actions. For example:
    #
    # def index
    #   super
    #   @resources = Plan.
    #     page(params[:page]).
    #     per(10)
    # end

    # Define a custom finder by overriding the `find_resource` method:
    # def find_resource(param)
    #   Plan.find_by!(slug: param)
    # end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information

    def create
      resource = resource_class.new(resource_params)
      Plan.transaction do
        if resource.save
          Plan.create_stripe_plan(resource)
          redirect_to(
            [namespace, resource],
            notice: translate_with_resource("create.success"),
          )
        else
          render :new, locals: {
            page: Administrate::Page::Form.new(dashboard, resource),
          }
        end
      end
    end

    def update
      Plan.transaction do
        if requested_resource.update(resource_params)
          Plan.update_stripe_plan(requested_resource)
          redirect_to(
            [namespace, requested_resource],
            notice: translate_with_resource("update.success"),
          )
        else
          render :edit, locals: {
            page: Administrate::Page::Form.new(dashboard, requested_resource),
          }
        end
      end
    end

    def destroy
      flash[:error] = "Prohibited!"
      redirect_to action: :index
    end

    private

    def find_resource(param)
      Plan.find_by(sku: param)
    end

  end

end
