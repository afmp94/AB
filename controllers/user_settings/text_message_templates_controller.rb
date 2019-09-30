class UserSettings::TextMessageTemplatesController < ApplicationController

  before_action :set_text_message_template, only: [:show, :edit, :update, :destroy]

  # GET /text_message_templates/1
  # GET /text_message_templates/1.json
  def show
    render
  end

  # GET /text_message_templates/new
  def new
    @text_message_template = current_user.text_message_templates.new
  end

  # GET /text_message_templates/1/edit
  def edit
    render
  end

  # POST /text_message_templates
  # POST /text_message_templates.json
  def create
    @text_message_template = current_user.text_message_templates.new(text_message_template_params)

    respond_to do |format|
      if @text_message_template.save
        format.html do
          redirect_to(
            edit_user_settings_phone_number_settings_url,
            notice: "Text message template was successfully created."
          )
        end
        format.json { render :show, status: :created, location: @text_message_template }
      else
        format.html { render :new }
        format.json { render json: @text_message_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /text_message_templates/1
  # PATCH/PUT /text_message_templates/1.json
  def update
    respond_to do |format|
      if @text_message_template.update(text_message_template_params)
        format.html do
          redirect_to(
            edit_user_settings_phone_number_settings_url,
            notice: "Text message template was successfully updated."
          )
        end
        format.json { render :show, status: :ok, location: @text_message_template }
      else
        format.html { render :edit }
        format.json
      end
    end
  end

  # DELETE /text_message_templates/1
  # DELETE /text_message_templates/1.json
  def destroy
    @text_message_template.destroy
    respond_to do |format|
      format.html do
        redirect_to(
          edit_user_settings_phone_number_settings_url,
          notice: "Text message template was successfully destroyed."
        )
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_text_message_template
    @text_message_template = TextMessageTemplate.
                               owned_and_shared_with(
                                 current_user.team_member_ids_except_self,
                                 current_user.id
                               ).
                               find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def text_message_template_params
    params.require(:text_message_template).permit(:name, :body, :shared, :user_id)
  end

end
