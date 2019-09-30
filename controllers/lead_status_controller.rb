class LeadStatusController < ApplicationController

  before_action :set_lead

  def lead
    new_status = 0
    validate_and_update(new_status)
  end

  def prospect
    new_status = 1
    validate_and_update(new_status)
  end

  def active
    new_status = 2
    validate_and_update(new_status)
  end

  def pending
    new_status = 3
    validate_and_update(new_status)
  end

  def closed
    new_status = 4
    validate_and_update(new_status)
  end

  def paused
    new_status = 5
    validate_and_update(new_status)
  end

  def not_converted
    new_status = 6
    validate_and_update(new_status)
  end

  def junk
    new_status = 7
    validate_and_update(new_status)
  end

  def long_term_prospect
    new_status = 8
    validate_and_update(new_status)
  end

  private

  def redirect_path
    request.referer || lead_path(@lead)
  end

  def set_lead
    @lead = Lead.find(params[:id])
  end

  def validate_and_update(new_status)
    if LeadServices::StatusChangeValidator.new(@lead).validate(new_status)
      update_status(new_status)
    else
      redirect_to needs_info_to_update_status_lead_path(@lead, new_status: new_status)
    end
  end

  def update_status(new_status)
    if @lead.update(status: new_status)
      redirect_to(
        redirect_path,
        notice: "The status of #{@lead.name} has been changed to "\
          "#{lead_status_to_s(new_status).downcase}."
      )
    else
      redirect_to(
        redirect_path,
        alert: "There was a problem updating #{@lead.name} to "\
          "#{lead_status_to_s(new_status).downcase}. Please try again."
      )
    end
  end

  def lead_status_to_s(status)
    Lead::STATUSES[status][0]
  end

end
