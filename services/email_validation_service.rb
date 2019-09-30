class EmailValidationService

  def validate_and_return(list)
    container = []
    array = list.split(",")
    array.each do |email|
      if ValidateEmail.valid?(email)
        container << email
      end
    end
    container.join(",")
  end

end
