class LeadBroadcastingService

  def perform
    Lead.where(
      state: ["new_lead","referred","re_broadcast", "manually_forward"]
    ).find_in_batches(batch_size: 100) do |leads|
      leads.each do |lead|
        if lead.broadcast_lead_now? || lead.re_broadcast_lead_now?
          LeadBroadcastingNotifierService.new(lead).process
        end
      end
    end
  end

end
