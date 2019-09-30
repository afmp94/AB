module Admin

  class SurveyResultsController < Admin::ApplicationController

    # To customize the behavior of this controller,
    # you can overwrite any of the RESTful actions. For example:
    #
    # def index
    #   super
    #   @resources = SurveyResult.
    #     page(params[:page]).
    #     per(10)
    # end

    def index
      respond_to do |format|
        format.html do
          super
          @resources = SurveyResult.all
        end

        format.csv do
          send_data(
            SurveyResult.to_csv,
            filename: "survey_results_#{DateTime.current}.csv",
            type: :csv
          )
        end
      end
    end

    # Define a custom finder by overriding the `find_resource` method:

    def find_resource(param)
      SurveyResult.find_by_survey_token!(params[:id])
    end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information

  end

end
