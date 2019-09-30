class UserSettings::TagsController < ApplicationController

  before_action :load_tag, only: [:edit, :update, :destroy]
  respond_to :html

  def index
    @contact_groups = current_user.owned_tags
  end

  def edit
    render "user_settings/tags/edit"
  end

  def update
    respond_to do |format|
      if @tag.update(tag_params)
        add_current_user_contact_groups_list
        format.html { redirect_to user_settings_tags_path, notice: "Tag was successfully updated." }
      else
        format.html { redirect_to user_settings_tags_path, notice: "The group already exist." }
      end
    end
  end

  def destroy
    ActsAsTaggableOn::Tag.destroy(params.require(:id))
    delete_current_user_contact_groups_list
    redirect_to(
      user_settings_tags_path,
      notice: "The group was deleted."
    )
  end

  private

  def load_tag
    @tag = ActsAsTaggableOn::Tag.find(params.require(:id))
  end

  def tag_params
    params.require(:acts_as_taggable_on_tag).permit(:id, :name)
  end

  def delete_current_user_contact_groups_list
    if !current_user.contact_groups_list.nil? &&
       (current_user.contact_groups_list.list.include? @tag.name)
      current_user.contact_groups_list.list -= [@tag.name]
      current_user.contact_groups_list.save!
    end
  end

  def add_current_user_contact_groups_list
    current_user.contact_groups_list.list += [@tag.name]
    current_user.contact_groups_list.save!
  end

end
