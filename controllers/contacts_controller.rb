class ContactsController < ApplicationController

  include RecentActivities

  before_action :load_contact, only: [
    :destroy,
    :destroy_from_grader,
    :edit,
    :edit_contact_correspondence,
    :edit_contact_details,
    :edit_contact_work_info,
    :grade,
    :nylas_report_info,
    :set_grade,
    :show,
    :update,
  ]
  before_action :load_contacts, only: [:index, :search_contacts]
  before_action :set_graded_contacts, only: [
    :destroy_from_grader,
    :rank,
    :top_contacts
  ]

  def index
    contacts_per_page
    session[:referring_page] = contacts_path
  end

  def show
    @commentable         = @contact
    @comments            = @commentable.comments
    @comment             = Comment.new
    @contact_activities  = @contact.contact_activities.order("completed_at desc")
    @contacts_page_url   = request.referer || contacts_path
    @not_completed_tasks = @contact.tasks.not_completed.order("due_date_at asc")
    @completed_tasks     = @contact.tasks.completed.order("completed_at desc")
    @phone_numbers       = @contact.phone_numbers
    @email_addresses     = @contact.email_addresses
    @activities, @activities_url = contact_activities(@contact, params[:activity_feed_page])
    @sms_message         = SmsMessage.new
    @contact_numbers     = @phone_numbers.pluck(:number)
    @sms_messages        = SmsMessage.
                             where(user: current_user, contact: @contact).
                             order(created_at: :desc).
                             includes(:image)
  end

  def edit
    @contact.addresses.build       if @contact.addresses.blank?
    @contact.phone_numbers.build   if @contact.phone_numbers.blank?
    @contact.email_addresses.build if @contact.email_addresses.blank?
    render
  end

  def update
    @inline_form = params[:inline_form]

    respond_to do |format|
      get_email_addresses_and_phone_numbers

      if @contact.update(contact_params)
        tag_contact_list

        format.html { redirect_to redirect_path, notice: "Contact successfully updated!" }
        format.json
      else
        format.html do
          flash.now[:danger] = "Please check your entry and try again."
          render :edit
        end

        format.json { render json: @lead.errors, status: :unprocessable_entity }
      end

      format.js
    end
  end

  def omnicontacts_gmail_callback
    contacts = request.env["omnicontacts.contacts"]

    if contacts.present?
      import_service = ImportGoogleContactsService.new(current_user.id, contacts)
      import_service.delay.process
      notice_message = "We got your contacts and importing will take few minutes"
    else
      notice_message = "Contacts not found!!!"
    end

    redirect_path = if current_user.onboarding_completed?
                      root_path
                    else
                      profile_steps_path(id: "other_information")
                    end

    redirect_to redirect_path, notice: notice_message
  end

  def batch_update
    respond_to do |format|
      if params[:contacts]
        @contacts = []
        params[:contacts].each do |contact_data|
          contact = current_user.contacts.find(contact_data[:id])
          if contact.update(permitted_params(contact_data))
            if contact_data[:contact_tag_list]
              Util.without_tracking do
                current_user.tag(contact, with: contact_data[:contact_tag_list], on: :contact_groups)
              end
            end
            @contacts << contact
          end
        end
        format.json
      end
    end
  end

  def new
    @contact = current_user.contacts.new
    @contact.addresses.build
    @contact.phone_numbers.build
    @contact.email_addresses.build
    session[:referring_page] = request.referer
  end

  def create
    @contact                 = current_user.contacts.build(contact_params)
    @contact.created_by_user = current_user
    @modal_id                = params[:modal_id]
    @target_select_id        = params[:target_select_id]
    @for_page                = params[:for_page]

    respond_to do |format|
      if @contact.save
        if params[:contact_tag_list].present?
          current_user.tag(@contact, with: params[:contact_tag_list], on: :contact_groups)
        end

        format.html do
          current_user.mark_initial_setup_done!
          if params[:btn_save_and_add_another].present?
            redirect_to new_contact_path, notice: "Contact successfully created!"
          else
            redirect_to session[:referring_page] || @contact, notice: "Contact successfully created!"
          end
        end
      else
        flash.now[:danger] = "Please check your entry and try again."
        format.html { render :new }
      end

      format.js unless forced_form_for_mobile_app?
    end
  end

  def destroy
    @contact.mark_as_inactive!
    redirect_path = request.referer.presence || contacts_path
    redirect_to redirect_path
  end

  def destroy_from_grader
    @contact.mark_as_inactive!
    set_ungraded_current_contact
    current_user.reload
    render "grade", layout: false
  end

  def destroy_multiple
    Contact.transaction do
      params[:ids]&.each do |id|
        current_user.contacts.find(id).mark_as_inactive!
      end
    end

    respond_to do |format|
      format.html { redirect_to contacts_url }
      format.json { head :no_content }
      format.js
    end
  end

  def duplicates
    @duplicate_contact_ids = DuplicateContactsIdentifier.new(current_user).duplicate_contacts
    dismissed_ids = current_user.dismissed_contacts.pluck(:contact_id)
    @all_duplicate_contacts = []
    single_duplicate_contacts = []
    @duplicate_contact_ids.each_with_index do |duplicate_contact, index|
      duplicate_contact = duplicate_contact - dismissed_ids
      if !duplicate_contact.empty?
        single_duplicate_contacts = Contact.find(duplicate_contact)
        @all_duplicate_contacts.push(single_duplicate_contacts)
      else
        @duplicate_contact_ids.delete(@duplicate_contact_ids[index])
      end
    end
  end

  def mass_update_for_grade
    contacts = current_user.contacts
    @old_ungraded_count = current_user.contacts.active.ungraded.count

    contacts.mass_grade_update(params[:ids], params[:grade])
    @new_ungraded_count = contacts.reload.active.ungraded.count

    if @old_ungraded_count != @new_ungraded_count
      current_user.update!(ungraded_contacts_count: @new_ungraded_count)
    end

    respond_to do |format|
      format.json do
        render json: {
          old_ungraded_count: @old_ungraded_count,
          new_ungraded_count: @new_ungraded_count
        }
      end
    end
  end

  def update_groups
    @contact = current_user.contacts.includes(:taggings).find(params[:id])
    groups   = params[:groups].presence || []

    current_user.tag(@contact, with: groups.join(", "), on: :contact_groups)
    @contact.touch(:updated_at)
  end

  def mass_update_for_groups
    @contacts = current_user.contacts.where(id: params[:ids])
    groups = params[:groups].presence || []
    @contacts.update_groups(groups)
  end

  def postponecall
    @contact = current_user.contacts.find(params[:contact_id])
    @contact.next_call_at = Time.zone.now.beginning_of_day + 7.days
    @contact.save!
    redirect_to marketing_center_index_path, notice: "Activity successfully postponed!"
  end

  def postponenote
    @contact = current_user.contacts.find(params[:contact_id])
    @contact.next_note_at = Time.zone.now.beginning_of_day + 7.days
    @contact.save!
    redirect_to marketing_center_index_path, notice: "Activity successfully postponed!"
  end

  def postponevisit
    @contact = current_user.contacts.find(params[:contact_id])
    @contact.next_visit_at = Time.zone.now.beginning_of_day + 7.days
    @contact.save!
    redirect_to marketing_center_index_path, notice: "Activity successfully postponed!"
  end

  def rank
    set_ungraded_current_contact
  end

  def set_grade
    @grade_was_nil = @contact.grade_was.nil?

    if @contact.update_attributes(grade: params[:grade_id], graded_at: Time.current)
      respond_to do |format|
        format.html { redirect_to contact_path(@contact), notice: "Successfully updated contact grade." }
        format.js { render layout: false }
      end
    else
      respond_to do |format|
        format.html { redirect_to contact_path(@contact), notice: "Error updating grade.." }
        format.js { render layout: false }
      end
    end
  end

  def top_contacts
    if params[:contact_id]
      if @current_contact = current_user.contacts.active.find_by(id: params[:contact_id])
        @current_contact
      else
        set_ungraded_current_contact
      end
    else
      set_ungraded_current_contact
    end
  end

  def search_top_contacts
    search_results = []
    contacts       = current_user.contacts.active.ungraded.search_name(params[:search_term])

    contacts.each do |contact|
      contact_url = if current_user.onboarding_completed?
                      top_contacts_path(contact_id: contact.id)
                    else
                      profile_steps_path(id: "rank_top_contacts", contact_id: contact.id)
                    end

      search_results << {
        contact_full_name: contact.full_name,
        contact_url: contact_url
      }
    end

    render json: { "results": search_results, "success": true }
  end

  def search_contacts_for_autocomplete
    search_results = []
    contacts = current_user.contacts.active.search_name(params[:search_term])

    contacts.each do |contact|
      search_results << {
        contact_full_name: contact.full_name,
        contact_id: contact.id
      }
    end

    render json: { "results": search_results, "success": true }
  end

  def grade
    if @contact.update_attributes(grade: params[:grade_id], graded_at: Time.current)
      current_user.mark_initial_setup_done!
      set_ungraded_current_contact
      current_user.reload # User object becomes stale after contact related updates.

      @graded_contacts = current_user.contacts.active.graded.order(graded_at: :desc).limit(10)
      @contact_graded_message = "Successfully graded contact #{@contact.full_name}."
      render "grade", layout: false
    else
      render(
        json: { notice: "Failed to rank contact." },
        status: :unprocessable_entity
      ) and return  # rubocop:disable Style/AndOr
    end
  end

  def search_contacts
    session[:contact_index_page] = params[:page] || nil
    render layout: false
  end

  def autocomplete_group_tags
    tags = ActsAsTaggableOn::Tagging.where("taggings.tagger_id = ? AND taggings.context = ? AND tags.name like ?",
                                           current_user.id, :contact_groups,
                                           "#{params[:term]}%").joins(:tag).select("DISTINCT tags.name").map(&:name)
    json_tags = []
    tags.each do |tag|
      json_tags << { label: tag }
    end
    render json: json_tags
  end

  def edit_contact_details
    @contact.addresses.build       if @contact.addresses.blank?
    @contact.phone_numbers.build   if @contact.phone_numbers.blank?
    @contact.email_addresses.build if @contact.email_addresses.blank?

    render "contacts/js/edit_contact_details"
  end

  def edit_contact_correspondence
    render "contacts/js/edit_contact_correspondence"
  end

  def edit_contact_work_info
    render "contacts/js/edit_contact_work_info"
  end

  def refresh_fullcontact_info
    contact = current_user.contacts.find(params[:id])
    lead = current_user.leads.find(params[:lead_id]) if params[:lead_id]

    contact.refresh_contact_api_info
    redirect_object = lead || contact
    if Contact.find(params[:id]).search_status == "Our API has found some information about this person"
      redirect_to redirect_object, notice: "Social info has been updated"
    else
      redirect_to(
        redirect_object,
        warning: "A search is either currently in progress, or no social info was found. Check again in a few minutes."
      )
    end
  end

  def email_campaigns_sent
    @contact = current_user.contacts.find(params[:id])
    @campaigns = CampaignMessage.where(contact_id: @contact.id)
    render
  end

  def fetch_address_with_jquery
    contact_id = params[:contact_id]
    contact = current_user.contacts.find(contact_id)
    address_string = create_contact_address_string(contact)
    respond_to do |format|
      format.json { render json: address_string }
    end
  end

  def open_contact_modal
    @contact = current_user.contacts.build
    @contact.addresses.build
    @contact.phone_numbers.build
    @contact.email_addresses.build
    @modal_id = params[:modal_id]
    @target_select_id = params[:target_select_id]
    @for_page = params[:for_page]
  end

  def nylas_report_info
    render layout: false
  end

  def stats
    render
  end

  def create_contact_from_onboarding_steps
    @contact                 = current_user.contacts.build(contact_params)
    @contact.created_by_user = current_user

    if @contact.save
      @contact = current_user.contacts.build
      @contact.email_addresses.build
      @contact.phone_numbers.build
    end
  end

  def merge_duplicate_data
    if params[:merge_all] == "false"
      duplicate_ids = params[:duplicate_ids].map(&:to_i)
      ContactMerger.new(duplicate_ids).merge
      flash[:notice] = "Contact Merged Successfully"
    else
      merge_all_duplicates
      flash[:notice] = "All Contacts Merged Successfully"
    end
    redirect_to duplicates_path
  end

  def merge_all_duplicates
    all_duplicate_ids = params["duplicate_ids"].as_json
    all_duplicate_ids.each_key do |key|
      duplicate_group = all_duplicate_ids[key].map(&:to_i)
      ContactMerger.new(duplicate_group).merge
    end
  end

  def dismiss_contacts
    dismissed_contact_ids = params[:dismissed_ids].map(&:to_i)
    dismissed_contact_ids.each do |dismissed_contact_id|
      current_user.dismissed_contacts.create(contact_id: dismissed_contact_id)
    end
    flash[:notice] = "Contacts Dismissed"
    redirect_to duplicates_path
  end

  def open_merge_modal
    @contact = current_user.contacts.find(params[:id])
    @total_contacts = current_user.contacts.where("id != ?", @contact.id)
    render "contacts/modals/open_merge_modal"
  end

  def merge_contacts
    contact_ids = params[:contact_ids].map(&:to_i)
    primary_contact = ContactMerger.new(contact_ids).merge
    if primary_contact
      flash[:notice] = "Contacts Merged Successfully"
    else
      flash[:error] = "Something went wrong! Unable to merge contacts"
    end
    redirect_to primary_contact
  end

  private

  def permitted_params(param_list)
    param_list.permit(
      :grade
    )
  end

  def contact_params
    params.require(:contact).permit(
      :name,
      :first_name,
      :last_name,
      :spouse_first_name,
      :spouse_last_name,
      :user_id,
      :grade,
      :envelope_salutation,
      :letter_salutation,
      :company,
      :profession,
      :title,
      :last_note_sent_at,
      :next_note_at,
      :last_called_at,
      :next_call_at,
      :last_visited_at,
      :next_visit_at,
      :require_base_validations,
      :require_basic_validations,
      :unsubscribed,
      addresses_attributes: [
        :id,
        :address,
        :address_type,
        :city,
        :state,
        :zip,
        :street,
        :require_basic_address_validations,
        :_destroy
      ],
      phone_numbers_attributes: [
        :id,
        :number,
        :number_type,
        :primary,
        :_destroy
      ],
      email_addresses_attributes: [
        :id,
        :email,
        :email_type,
        :primary,
        :_destroy
      ],
      important_dates_attributes: [
        :id,
        :name,
        :date_at,
        :date_type,
        :_destroy
      ]
    )
  end

  def load_contact
    @contact = current_user.contacts.find(params[:id])
  end

  def load_contacts
    @contacts = Contacts::LoadService.new(current_user, params).get
    @contacts = if @contacts.count > Contact.per_page
                  @contacts.page(params[:page].presence || 1)
                else
                  @contacts.page(1)
                end

    contacts_per_page
  end

  def set_ungraded_current_contact
    @current_contact = current_user.contacts.active.random_ungraded_contact params[:dont_rank]
  end

  def set_graded_contacts
    @graded_contacts = current_user.contacts.active.graded.order(graded_at: :desc).limit(10)
  end

  def create_contact_address_string(contact)
    address = contact.primary_address
    address_string = ""
    if address

      if address.street
        address_string += " present *****"
        address_string += " #{address.street} *****"
      else
        address_string += " nopresence *****"
        address_string += " EMPTY *****"
      end

      if address.city
        address_string += " present *****"
        address_string += " #{address.city} *****"
      else
        address_string += " nopresence *****"
        address_string += " EMPTY *****"
      end

      if address.state
        address_string += " present *****"
        address_string += " #{address.state} *****"
      else
        address_string += " nopresence *****"
        address_string += " EMPTY *****"
      end

      if address.zip
        address_string += " present *****"
        address_string += " #{address.zip} *****"
      else
        address_string += " nopresence *****"
        address_string += " EMPTY *****"
      end

    end
    address_string
  end

  def contacts_per_page
    @contacts = @contacts.per(Contact::PER_PAGE)
  end

  def get_email_addresses_and_phone_numbers
    @phone_numbers   = @contact.phone_numbers
    @email_addresses = @contact.email_addresses
  end

  def tag_contact_list
    if params[:contact_tag_list]
      Util.without_tracking do
        current_user.tag(@contact, with: params[:contact_tag_list], on: :contact_groups)
      end
    end
  end

  def redirect_path
    if params[:btn_save_and_add_another].present?
      new_contact_path
    else
      session[:referring_page]
    end
  end

end
