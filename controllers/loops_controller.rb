class LoopsController < ApplicationController

  def create
    lead_id = params[:lead_id]
    action_type =  params[:dotloop_action]
    message = "Loop created successfully"
    if action_type == "existing-loop"
      message = "Lead linked to loop successfully"
    end
    loops = dotloop_action_type(params)
    loop_url = loop_url(loops)
    if loops.present?
      loop_creation(loops, loop_url, lead_id)
      adding_dotloop_participants(lead_id)
      sync_contract_data_to_dotloop(lead_id)
      flash[:notice] = message
    else
      flash[:error] = "You have reached your LOOP limit in DOTLOOP. Please sign in to DOTLOOP to upgrade."
    end
    redirect_to lead_path(lead_id)
  end

  def adding_dotloop_participants(lead_id)
    DotloopService.new.refresh_dotloop_token(current_user)
    set_dotloop_client = DotloopService.new.set_dotloop_client(current_user)
    lead = Lead.find(lead_id)
    DotloopParticipantSync.participants_processing(lead, set_dotloop_client)
    DotloopParticipantSync.contract_processing(lead, set_dotloop_client)
  end

  def loop_creation(loops, loop_url, lead_id)
    Loop.create(loops_params(loops, loop_url, lead_id))
  end

  def sync_contract_data_to_dotloop(lead_id)
    lead = Lead.find(lead_id)
    DotloopService.new.refresh_dotloop_token(current_user)
    set_dotloop_client = DotloopService.new.set_dotloop_client(current_user)
    data_synchronizer_service = DotloopService::DataSynchronizer.new(lead, current_user)
    data1 = data_synchronizer_service.agentbright_to_dotloop
    data2 = data_synchronizer_service.loop_basic_field_data
    data_synchronizer_service.update_loop_status(data2, lead, set_dotloop_client)
    data_synchronizer_service.update_loop_details(data1, lead, set_dotloop_client)
  end

  def destroy
    lead = Lead.find(params[:id])
    lead.loop.destroy
    flash[:notice] = "Successfully disconnected loop from lead"
    redirect_to lead_path(lead.id)
  end

  def get_loops_by_templates
    profile_id = params[:profile_id]
    set_dotloop_client = DotloopService.new.set_dotloop_client(current_user)
    loops = set_dotloop_client.Loop.all(profile_id: profile_id)
    present_loops = Loop.all.map(&:loop_id)
    loops = loops.delete_if { |x| present_loops.include? x.id }
    render json: { loops: loops }
  end

  private

  def set_loops(params)
    profile_id = params[:profile_id]
    template_id = params[:template_id]
    lead = Lead.find(params[:lead_id])
    data = loop_it(lead, params)
    DotloopService.new.refresh_dotloop_token(current_user)
    set_dotloop_client = DotloopService.new.set_dotloop_client(current_user)
    if DotloopService.new.requires_templates?(set_dotloop_client, profile_id)
      data["templateId"] = template_id
    end
    begin
      loops = set_dotloop_client.Profile.find(profile_id: profile_id).loop_it(data)
    rescue StandardError
      loops = nil
    end
    loops
  end

  def loop_it(lead, params)
    template_id = params[:template_id]
    if lead.client_type == "Seller"
      status = DotloopService.new(lead).client_type_seller_status
      DotloopService.new(lead).data_for_seller(status, current_user, template_id)
    elsif lead.client_type == "Buyer"
      status = DotloopService.new(lead).clent_type_buyer_status
      DotloopService.new(lead).data_for_buyer(status, current_user, template_id)
    end
  end

  def dotloop_action_type(params)
    action_type =  params[:dotloop_action]
    if action_type == "new-loop"
      loops = set_loops(params)
    elsif action_type == "existing-loop"
      loops = DotloopService.new.linked_to_existing_loop(params, current_user)
    end
    loops
  end

  def loop_url(loops)
    if loops.present? && loops["loop_url"].present?
      loop_url = loops["loop_url"]
    elsif loops.present? && loops["loopUrl"].present?
      loop_url = loops["loopUrl"]
    end
    loop_url
  end

  def loops_params(loops, loop_url, lead_id)
    {
      loop_id: loops["id"],
      profile_id: loops["profile_id"] || loops["profileId"],
      lead_id: lead_id,
      transaction_type: loops["transaction_type"] || loops["transactionType"],
      loop_url: loop_url,
      status: loops["status"]
    }
  end

end
