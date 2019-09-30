class DotloopParticipantSync

  def self.participants_processing(lead, set_dotloop_client)
    key_participant_data_with_ids = []
    key_participant_data_with_ids = key_people_unsynced_participants(lead, key_participant_data_with_ids, true)
    key_participant_data_with_ids.each do |key_participant_hash|
      ab_participant_id = key_participant_hash["id"]
      key_participant_hash.delete("id")
      response = add_participant_from_agentbright_to_dotloop(key_participant_hash, lead, set_dotloop_client)
      key_participant_hash["id"] = ab_participant_id
      add_participant_details(response, lead, key_participant_hash)
    end
    update_synced_key_persons(lead)
  end

  def self.add_participant_details(response, lead, params, contract_exist=false)
    if response.code == "201"
      dotloop_participant_id = JSON.parse(response.body)["data"]["id"]
      lead_id = lead.id
      if !contract_exist
        participant_id = params["id"]
        KeyPersonLog.create(
          lead_id: lead_id,
          participant_id: participant_id,
          dotloop_participant_id: dotloop_participant_id
        )
      else
        contract_id = params["contract_id"]
        KeyPersonLog.create(
          lead_id: lead_id,
          contract_id: contract_id,
          dotloop_participant_id: dotloop_participant_id
        )
      end
    end
  end

  def self.contract_processing(lead, set_dotloop_client)
    contract_data_with_id = unsync_contracts(lead, true)

    contract_data_with_id["contract_data"].each do |contract_data|
      response = add_participant_from_agentbright_to_dotloop(contract_data, lead, set_dotloop_client)
      add_participant_details(response, lead, contract_data_with_id, true)

    end
  end

  def self.unsync_contracts(lead, append_id=false)
    data = {}
    contract_data = []
    if lead.client_type == "Seller"
      # status = DotloopService.new(lead).client_type_seller_status
      # DotloopService.new(lead).data_for_seller(status, current_user, template_id)

      accepted_listing_contract = lead.accepted_listing_contract

      contact = accepted_listing_contract

      if accepted_listing_contract&.buyer&.present?
        contract_data << {
          "fullName": accepted_listing_contract.buyer,
          "role": "BUYER"
        }

        contract_data << {
          "fullName": accepted_listing_contract.buyer_agent,
          "role": "BUYING_AGENT"
        }
      end

    elsif lead.client_type == "Buyer"
      # status = DotloopService.new(lead).clent_type_buyer_status
      # DotloopService.new(lead).data_for_buyer(status, current_user, template_id)

      contract = lead.accepted_buyer_contract

      if lead.accepted_buyer_contract&.seller&.present?
        contract_data << {
          "fullName": lead.accepted_buyer_contract.seller,
          "role": "SELLER"
        }

        contract_data << {
          "fullName": lead.accepted_buyer_contract.seller_agent,
          "role": "LISTING_BROKER"
        }

      end

    end

    data["contract_data"] = contract_data
    data["contract_id"] = contract.id if append_id
    # contract_data << {"contract_id" => contract.id} if append_id
    # contract_data
    data
  end

  def self.update_synced_key_persons(lead)
    lead_key_person_ids = Lead.find(lead.id).key_person_ids
    KeyPerson.where(id: lead_key_person_ids).update_all(sync_participant_role: true)
  end

  def self.key_people_unsynced_participants(lead, key_person_hash, append_id=false)
    lead.key_people.where(sync_participant_role: false).each do |people|
      key_person = {
        "email": people.contact.email,
        "fullName": people.contact.name,
        "role": DotloopService.new.key_person_role(people.role_type)
      }

      key_person["id"] = people.id if append_id
      key_person_hash << key_person
    end
    key_person_hash = remove_email_duplication(key_person_hash)
    key_person_hash
  end

  def self.remove_email_duplication(data)
    response_arr = []
    data.flatten.compact.each do |p|
      val = response_arr.map { |a| a[:email] }.include?(p[:email]) ? { fullName: p[:fullName], role: p[:role] } : p
      response_arr << val
    end
    data = response_arr
    data
  end

  def self.add_participant_from_agentbright_to_dotloop(data, lead, set_dotloop_client)
    require "net/http"
    require "uri"
    require "json"
    loop_id = lead.loop.loop_id
    profile_id = lead.loop.profile_id
    uri = URI.parse("https://api-gateway.dotloop.com/public/v2/profile/#{profile_id}/loop/#{loop_id}/participant")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{set_dotloop_client.access_token}"
    request.body = data.to_json

    req_options = {
      use_ssl: uri.scheme == "https"
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    response
  end

  def self.sync_deleted_participants(lead, set_dotloop_client)
    loop = lead.loop
    loop_id = loop.loop_id
    profile_id = loop.profile_id
    deleted_key_people = KeyPersonLog.where(lead_id: lead.id, is_deleted: true)
    deleted_key_people.each do |participant|
      delete_keyperson_from_dotloop(loop_id, profile_id, participant, set_dotloop_client)
    end
  end

  def self.delete_keyperson_from_dotloop(loop_id, profile_id, dotloop_participant, set_dotloop_client)
    require "net/http"
    require "uri"
    require "json"
    api_call_url = "profile/#{profile_id}/loop/#{loop_id}/participant/#{dotloop_participant.dotloop_participant_id}"
    uri = URI.parse(
      "https://api-gateway.dotloop.com/public/v2/" + api_call_url
    )
    request = Net::HTTP::Delete.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{set_dotloop_client.access_token}"
    req_options = {
      use_ssl: uri.scheme == "https"
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    dotloop_participant.destroy if response.code == "204"
    response
  end

end
