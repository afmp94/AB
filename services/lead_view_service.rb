class LeadViewService

  attr_accessor :lead

  def initialize(lead)
    @lead = lead
  end

  def user_initials
    if @lead.user
      @lead.user.initials.upcase
    elsif @lead.created_by_user
      @lead.created_by_user.initials.upcase
    else
      'NA'
    end
  end

  def user_name
    if @lead.user
      @lead.user.full_name
    elsif @lead.created_by_user
      @lead.created_by_user.full_name
    else
      'Undefined'
    end
  end

end
