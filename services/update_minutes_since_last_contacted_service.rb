class UpdateMinutesSinceLastContactedService

  def perform
    Contact.where.not(last_contacted_at: nil).find_in_batches(batch_size: 100) do |group|
      group.each do |contact|
        diff = Time.current - contact.last_contacted_at
        diff_in_minutes = diff/60
        contact.update_attributes! minutes_since_last_contacted: diff_in_minutes.to_i
      end
    end
  end

end
