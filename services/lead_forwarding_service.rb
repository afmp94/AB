class LeadForwardingService

  def perform
    Lead.where(state: "new_lead").find_in_batches(batch_size: 100) do |leads|
      leads.each do |lead|
        if lead.forward_lead_now?
          LeadForwardingNotifierService.new(lead).process
        end
      end
    end
  end

end
