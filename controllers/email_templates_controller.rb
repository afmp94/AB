class EmailTemplatesController < ApplicationController

  before_action :set_email_template, only: %i(edit update copy destroy)
  before_action :redirect_with_message, only: %i(edit update copy destroy)

  def index
    @email_templates = current_user.email_templates
  end

  def new
    @email_template = current_user.email_templates.new
  end

  def create
    email_template = current_user.email_templates.new(email_template_params)
    if email_template.save
      flash[:notice] = "Email template has been created successfully"
      redirect_index
    else
      flash[:error] = email_template.errors.full_messages.join(",")
      redirect_to new_email_template_path
    end
  end

  def edit; end

  def update
    if @email_template.update(email_template_params)
      flash[:notice] = "Email template has been updated successfully"
      redirect_index
    else
      flash[:error] = @email_template.errors.full_messages.join(",")
      redirect_to edit_email_template_path(@email_template)
    end
  end

  def copy
    copied_record = @email_template.duplicate
    copied_record.save
    flash[:notice] = "Email template has been copied successfully"
    redirect_to edit_email_template_path(copied_record)
  end

  def destroy
    if @email_template.destroy
      flash[:notice] = "Email template has been deleted successfully"
    else
      flash[:error] = @email_template.errors.full_messages.join(",")
    end
    redirect_index
  end

  private

  def email_template_params
    params.require(:email_template).permit(:name, :purpose, :subject, :message_body, :use_default_signature)
  end

  def set_email_template
    @email_template = current_user.email_templates.find_by(id: params[:id])
  end

  def redirect_index
    redirect_to email_templates_path
  end

  def redirect_with_message
    redirect_to email_templates_path, notice: "You are not authorized" if @email_template.blank?
  end

end
