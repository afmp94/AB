module Contacts

  class LoadService

    attr_reader :user, :params

    def initialize(user, params)
      @user   = user
      @params = params
    end

    def get
      contacts = user.contacts.active.includes(:taggings)

      @searched_contacts = if params[:search_term].present?
                             contacts.search_name(params[:search_term])
                           else
                             contacts
                           end

      searched_contacts_with_groups if params[:groups].present?
      searched_contacts_with_grades if params[:grades].present?

      @searched_contacts.order(order_condition)
    end

    private

    def searched_contacts_with_grades
      grades = params[:grades]

      if grades.present?
        @searched_contacts = @searched_contacts.graded_for(grades.split(","))
      end
    end

    def searched_contacts_with_groups
      groups = params[:groups]

      if groups.present?
        @searched_contacts = @searched_contacts.tagged_with(groups, any: true)
      end
    end

    def order_condition
      order_by       = params[:order_by] || "first_name"
      sort_direction = params[:sort_direction] || "asc"

      case order_by
      when "first_name"
        { "#{order_by}": sort_direction, last_name: :asc }
      when "last_name"
        { "#{order_by}": sort_direction, first_name: :asc }
      else
        { "#{order_by}": sort_direction }
      end
    end

  end

end
