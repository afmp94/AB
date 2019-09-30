class TasksController < ApplicationController

  include RecentActivities

  before_action :set_task, only: [
    :assign_due_date,
    :destroy,
    :edit,
    :postpone,
    :show,
    :toggle,
    :update
  ]
  before_action :load_taskable
  before_action only: [:assign_due_date, :destroy, :edit, :new, :open_task_modal, :toggle] do
    set_referring_page_with_backup(tasks_path)
  end

  def index
    @user = current_user
    @not_completed_tasks = @user.tasks_assigned.not_completed.order("due_date_at asc")
    @not_completed_tasks_assigned_to_other_teammates = @user.team_tasks_assigned_to_other_teammates.
                                                       not_completed.order("due_date_at asc")
    @completed_tasks = @user.team_tasks.completed.order("completed_at desc").limit(5)
    @completed_tasks_count = @user.team_tasks.completed.order("completed_at desc").count
    set_referring_page(tasks_path)
  end

  def new
    @task = @taskable.tasks.new
    @task_carrier = TaskCarrier.new(@task)

    set_add_from_show_page

    @task.assigned_to = current_user
  end

  def create
    @task = Task.new(task_params)

    @task_carrier = TaskCarrier.new(@task)
    set_created_task_params

    respond_to do |format|
      if @task.save
        format.html do
          redirect_to(
            session[:referring_page] || dashboard_path,
            notice: "Task successfully created!"
          )
        end
        format.json { render action: "task", status: :created, location: @task }

        unless forced_form_for_mobile_app?
          format.js do
            task_owner_recent_activities # only for JS request.
          end
        end
      else
        @task_errors = @task.errors.full_messages
        format.html do
          flash.now[:danger] = "Please check your entry and try again."
          render :new
        end
        format.json { render json: @task.errors, status: :unprocessable_entity }
        format.js unless forced_form_for_mobile_app?
      end
    end
  end

  def show
    redirect_to edit_task_path(params[:id])
  end

  def edit
    @task_carrier = TaskCarrier.new(@task)
  end

  def assign_due_date
    render
  end

  def update
    @task_carrier = TaskCarrier.new(@task)
    set_completed_params_if_completed_is_updated

    respond_to do |format|
      if @task.update(task_params)
        format.html { redirect_to session[:referring_page] || @task, notice: "Task was successfully updated." }
        format.json { head :no_content }
      else
        format.html do
          flash.now[:danger] = "Please check your entry and try again."
          render :edit
        end
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
      format.js unless forced_form_for_mobile_app?
    end
  end

  def destroy
    @task.destroy
    respond_to do |format|
      format.html { redirect_to dashboard_path }
      format.js
      format.json { head :no_content }
    end
  end

  def toggle
    toggle_task_attributes
    @task.update(task_params)

    if params[:from_page] == "home-index" && @task.belongs_to_lead?
      @task_carrier = TaskCarrier.new(@task)
      @taskable = @task.taskable
      @incompleted_tasks = @taskable.incomplete_tasks

      if @incompleted_tasks.blank?
        @new_task = @taskable.tasks.new
        @new_task.assigned_to = current_user
      end
    end

    # Currently we handle only JS reqeust so keeping this code open. If there
    # is another request other than JS request then we need to wrap
    # `task_owner_recent_activities`into format.js block. Because this code loads data
    # from the datbase which we currently only need for JS request.
    task_owner_recent_activities
  end

  def postpone
    set_referring_page_with_backup(@task)

    if @task.update_attributes(postpone: params[:postpone])
      redirect_to session[:referring_page], notice: "Task successfully postponed."
    else
      redirect_to session[:referring_page], danger: "Error updating task."
    end
  end

  def open_task_modal
    @new_task = @taskable.tasks.new
    @new_task_carrier = TaskCarrier.new(@new_task)

    set_add_from_show_page

    @new_task.assigned_to = if params[:task_for_teammate]
                              User.find(current_user.team_member_ids_except_self.first)
                            else
                              current_user
                            end
  end

  def all_completed
    @tasks_grouped_by_day = current_user.team_tasks.completed.includes(:taskable).
                            order("completed_at desc").
                            group_by { |task| task.completed_at.strftime("%B %-d") }
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def set_created_task_params
    @task.user = current_user
    if task_params[:completed] == "1"
      @task.completed_by = current_user
      @task.completed_at = Time.current
      @task.activity(key: "task.complete")
    end
    if params[:source] == "dashboard"
      session[:referring_page] = dashboard_url
    end
  end

  def set_completed_params_if_completed_is_updated
    if @task.completed && task_params[:completed] == "0"
      @task.completed_by = nil
      @task.completed_at = nil
    elsif @task.completed == false && task_params[:completed] == "1"
      @task.completed_by = current_user
      @task.completed_at = Time.current
      @task.activity(key: "task.complete")
    end
  end

  def toggle_task_attributes
    if task_params[:completed] == "1"
      @task.completed_by = current_user
      @task.completed_at = Time.current
      @task.activity(key: "task.complete")
    else
      @task.completed_by = nil
      @task.completed_at = nil
    end
  end

  def set_add_from_show_page
    @add_from_show_page = @taskable != current_user
  end

  def load_taskable
    if params[:lead_id]
      @taskable = Lead.find(params[:lead_id])
      @taskabletype = "Lead"
      @taskableid = @taskable.id
    elsif params[:contact_id]
      @taskable = Contact.find(params[:contact_id])
      @taskabletype = "Contact"
      @taskableid = @taskable.id
    else
      @taskable = current_user
    end
  end

  def task_params
    params.require(:task).permit(
      :assigned_to_id,
      :client_id,
      :completed,
      :completed_at,
      :completed_by_id,
      :contact_id,
      :due_date_at,
      :is_next_action,
      :lead_id,
      :postpone,
      :next_action,
      :subject,
      :taskable_id,
      :taskable_type,
      :type_associated,
      :user_id
    )
  end

  def task_owner_recent_activities
    if params[:from_page] == "home-index"
      user_all_activities
    else
      case @task.taskable_type
      when "Lead"
        @lead = @task.taskable
        @lead_recent_activities, @activities_url = lead_activities(@lead, params[:activity_feed_page])
      when "Contact"
        @contact = @task.taskable
        @contact_recent_activities, @activities_url = contact_activities(@contact, params[:activity_feed_page])
      end
    end
  end

  def user_all_activities
    @user_all_activities = true
    @activities, @activities_url = team_activities(current_user, params[:activity_feed_page])
  end

end
