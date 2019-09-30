module Admin

  class UsersController < Admin::ApplicationController

    include UserCreationControllerCallbacksHelper

    # To customize the behavior of this controller,
    # you can overwrite any of the RESTful actions. For example:
    #
    # def index
    #   super
    #   @resources = User.
    #     page(params[:page]).
    #     per(10)
    # end

    # Define a custom finder by overriding the `find_resource` method:
    # def find_resource(param)
    #   User.find_by!(slug: param)
    # end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information

    def create
      # Overridden method from adminstrate gem
      resource = resource_class.new(resource_params)

      if resource.save
        after_user_creation_callbacks(resource) if resource.valid?
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

    def update
      # Overridden method from adminstrate gem
      params[:user].delete(:password) if params[:user][:password].blank?
      params[:user].delete(:password_confirmation) if params[:user][:password_confirmation].blank?

      super
    end

    def destroy
      user = User.find_by(id: params[:id])
      user.destroy
      redirect_to(
        admin_users_path,
        notice: "User has been deleted successfuly!"
      )
    end

    def update_lead_settings
      user = User.find_by(id: params[:id])
      if user
        user_lead_setting = user.lead_setting
        LeadSetting::ATTRS_TO_UPDATE_ON_SUBSCRIPTION_DEACTIVATE.each do |attribute|
          user_lead_setting[attribute.to_sym] = false
        end
        user_lead_setting.save
      end
      redirect_to(
        admin_users_path,
        notice: "Notification settings updated successfuly!"
      )
    end
  end
end
