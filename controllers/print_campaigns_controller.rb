class PrintCampaignsController < ApplicationController

  before_action :load_print_campaigns, only: %i(index search_print_campaigns)
  before_action :set_print_campaign, only: %i(
    destroy
    download_campaign_labels
    edit
    replicate
    show
    update
  )

  def index
    @print_campaigns = current_user.print_campaigns.order("created_at desc")
    @print_campaigns = @print_campaigns.page(params[:page] || 1).per(PrintCampaign::PER_PAGE)
  end

  def new
    @print_campaign = current_user.print_campaigns.new
  end

  def create
    @print_campaign = current_user.print_campaigns.new(print_campaign_params)
    @print_campaign.pdf_created_at = Time.zone.now
    @print_campaign.printed = false

    if @print_campaign.save!
      redirect_to(@print_campaign, notice: "Labels are ready to be downloaded!")
    else
      flash.now[:danger] = "Please check your entry and try again."
      render :new
    end
  end

  def show
    render
  end

  def edit
    render
  end

  def update
    @print_campaign.update(print_campaign_params)
    set_contacts_receiving_campaign

    if @print_campaign.save!
      redirect_to(
        @print_campaign,
        notice: "Print Campaign was successfully updated."
      )
    else
      flash.now[:danger] = "Please check your entry and try again."
      render :edit
    end
  end

  def destroy
    @print_campaign.destroy
    respond_to do |format|
      format.html { redirect_to print_campaigns_url }
      format.json { head :no_content }
    end
  end

  def replicate
    print_campaign_copy = duplicated_print_campaign

    if print_campaign_copy.save!
      redirect_to(
        print_campaigns_path,
        notice: "Successfully replicated campaign"
      )
    else
      redirect_to(
        print_campaigns_path,
        notice: "There was an error replicating your print campaign. Please try again"
      )
    end
  end

  def download_campaign_labels
    quantity = 0
    set_contacts_receiving_campaign
    set_avery_label_type

    if @contacts.present?
      label_texts = @contacts.map { |contact| assemble_label_address(contact) }

      @labels = Prawn::Labels.render(label_texts, type: @type, shrink_to_fit: true) do |pdf, label_text|
        quantity = quantity += 1

        unless pdf.font_families.key?("Arial")
          pdf.font_families.update(
            "Arial" => {
              normal: Rails.root.join("app", "assets", "fonts", "font-for-pdf", "arial.ttf"),
              bold: Rails.root.join("app", "assets", "fonts", "font-for-pdf", "arial_bold.ttf"),
              italic: Rails.root.join("app", "assets", "fonts", "font-for-pdf", "arial_italic.ttf")
            }
          )
        end

        pdf.font "Arial"
        pdf.text(label_text)
      end

      send_data(
        @labels,
        filename: pdf_file_name(@print_campaign),
        type: "application/pdf"
      )

      @print_campaign.update!(
        quantity: quantity,
        pdf_created_at: Time.zone.now,
        printed: true
      )
    else
      redirect_to(
        edit_print_campaign_path(@print_campaign),
        danger: "Sorry there were no contact selected. Please try again"
      )
    end
  end

  def search_print_campaigns
    render layout: false
  end

  def destroy_multiple
    PrintCampaign.transaction do
      params[:ids]&.each do |id|
        current_user.print_campaigns.find(id).destroy!
      end
    end

    respond_to do |format|
      format.html { redirect_to print_campaigns_url }
      format.json { head :no_content }
    end
  end

  private

  def set_print_campaign
    @print_campaign = PrintCampaign.find(params[:id])
  end

  def set_contacts_receiving_campaign
    selected_recipient_type = @print_campaign.recipient_type
    if selected_recipient_type.zero?
      clear_recipient_fields
      @contacts = current_user.contacts.all.active
    elsif selected_recipient_type == 1
      clear_recipient_fields
      @contacts = get_contacts_from_selected_groups
    elsif selected_recipient_type == 2
      clear_recipient_fields
      @contacts = get_contacts_from_selected_grades
    end
  end

  def get_contacts_from_selected_groups
    current_user.contacts.active.tagged_with(@print_campaign.groups, any: true)
  end

  def get_contacts_from_selected_grades
    current_user.contacts.active.where(grade: @print_campaign.grades)
  end

  def clear_recipient_fields
    @print_campaign.quantity = nil
    if @print_campaign.recipient_type.zero?
      @print_campaign.groups, @print_campaign.grades = [""]
    elsif @print_campaign.recipient_type == 1
      @print_campaign.grades = [""]
    elsif @print_campaign.recipient_type == 2
      @print_campaign.groups = [""]
    end
  end

  def duplicated_print_campaign
    campaign_copy = @print_campaign.dup
    campaign_copy.name = "#{campaign_copy.name} (Copy)"
    campaign_copy.pdf_created_at = Time.zone.now
    campaign_copy.printed_at
    campaign_copy.printed = false
    campaign_copy
  end

  def set_avery_label_type
    label_size = @print_campaign.label_size
    if label_size == "5160"
      @type = "Custom5160"
    elsif label_size == "5163"
      @type = "Avery5163"
    elsif label_size == "7160"
      @type = "Custom5160" # note this is the same size as 5160
    end
  end

  def load_print_campaigns
    order_by = params[:order_by] || "Title"
    sort_direction = params[:sort_direction] || "asc"

    @print_campaigns = filtered_print_campaigns.order("#{order_by} #{sort_direction}").page(params[:page])
  end

  def searched_print_campaigns
    if params[:search_term].present?
      current_user.print_campaigns.search_name(params[:search_term])
    else
      current_user.print_campaigns
    end
  end

  def filtered_print_campaigns
    printed = params[:printed]

    if printed && printed != "all"
      case printed
      when "draft"
        searched_print_campaigns.labels_draft
      when "printed"
        searched_print_campaigns.labels_printed
      else
        searched_print_campaigns
      end
    else
      searched_print_campaigns
    end
  end

  def assemble_label_address(contact)
    name = contact.name
    address_line1 = contact.primary_address.try(:street)
    address_line2 = contact.primary_address.try(:city_state_zip)

    [name, address_line1, address_line2].join("\n")
  end

  def pdf_file_name(print_campaign)
    "Mailing Labels - #{print_campaign.name || 'Untitled'} - "\
      "#{Time.zone.now.to_date.to_s(:cal_date)}.pdf"
  end

  def print_campaign_params
    params.require(:print_campaign).permit(
      :contact_id,
      :contacts,
      :label_size,
      :lead_id,
      :name,
      :pdf_created_at,
      :printed,
      :printed_at,
      :quantity,
      :recipient_type,
      :title,
      :user_id,
      grades: [],
      groups: [],
    )
  end

end
