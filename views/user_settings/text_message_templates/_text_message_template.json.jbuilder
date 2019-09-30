json.extract! text_message_template, :id, :name, :body, :shared, :user_id, :created_at, :updated_at
json.url text_message_template_url(text_message_template, format: :json)
