class DotloopSyncController < ApplicationController

  def update
    lead = Lead.find(params[:id])
    type = params[:type]
    response = action_type(lead, type)
    if response.try(:code).present?
      flash_msg(response)
    elsif !response.nil? && response.financials.present?
      flash[:notice] = "Data Successfuly sync from dotloop to agentbright."
    else
      change_participant_role_if_not_succeed(lead)
      flash[:error] = "Error while updating loop, please try again"
    end
    redirect_to lead_path(lead)
  end

  private

  def flash_msg(response)
    if response.code == "200"
      flash[:notice] = "Data Successfuly sync from agentbright to dotloop."
    else
      flash[:error] = "Error while updating loop."
    end
  end

  def action_type(lead, type)
    DotloopService.new.refresh_dotloop_token(current_user)
    set_dotloop_client = DotloopService.new.set_dotloop_client(current_user)
    if type == "dotloop_to_ab"
      response = get_loop_detail(lead, set_dotloop_client)
      DotloopService::DataSynchronizer.new(lead, current_user).dotloop_to_agentbright(response) if response.present?
    else
      DotloopParticipantSync.participants_processing(lead, set_dotloop_client)
      DotloopParticipantSync.sync_deleted_participants(lead, set_dotloop_client)
      response = send("#{lead.client_type.downcase}_data".to_sym, lead, set_dotloop_client)
    end
    response
  end

  def change_participant_role_if_not_succeed(lead)
    lead_key_person_ids = Lead.find(lead.id).key_person_ids
    KeyPerson.where(id: lead_key_person_ids).update_all(sync_participant_role: false)
  end

  def buyer_data(lead, set_dotloop_client)
    data_sync_service = DotloopService::DataSynchronizer.new(lead, current_user)
    data1 = data_sync_service.agentbright_to_dotloop
    data2 = data_sync_service.loop_basic_field_data
    data_sync_service.update_loop_status(data2, lead, set_dotloop_client)
    data_sync_service.update_loop_details(data1, lead, set_dotloop_client)
  end

  def seller_data(lead, set_dotloop_client)
    data_sync_service = DotloopService::DataSynchronizer.new(lead, current_user)
    data1 = DotloopService::SellerData.new(lead).seller_data
    data2 = data_sync_service.loop_basic_field_data
    data_sync_service.update_loop_status(data2, lead, set_dotloop_client)
    data_sync_service.update_loop_details(data1, lead, set_dotloop_client)
  end

  def get_loop_detail(lead, set_dotloop_client)
    loop_id = lead.loop.loop_id
    profile_id = lead.loop.profile_id
    begin
      loop_details = set_dotloop_client.Loop.find(profile_id: profile_id, loop_id: loop_id).detail
    rescue StandardError
      loop_details = nil
    end
    loop_details
  end

end
