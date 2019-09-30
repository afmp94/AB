class UpdateCommissionDataService

  attr_reader :leads

  def initialize(leads)
    @leads = leads
  end

  def process
    @leads.each do |lead|
      LeadUpdateDisplayedFieldsService.new(lead).update_commission_data
    end
  end

end
