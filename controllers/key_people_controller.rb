class KeyPeopleController < ApplicationController

  def destroy
    @key_person = KeyPerson.find(params[:id])
    @key_person.destroy
  end

end
