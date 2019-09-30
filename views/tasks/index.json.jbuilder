json.array!(@tasks) do |task|
  json.extract! task, :id, :subject, :assigned_to, :due_date_at, :completed, :taskable_id, :taskable_type, :user_id
  json.url task_url(task, format: :json)
end
