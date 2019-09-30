module MailchimpApi

  class UpdateMemberListService

    attr_reader :list_id, :email, :subscribing_list_id

    def initialize(list_id, email, subscribing_list_id)
      @list_id             = list_id
      @email               = email
      @subscribing_list_id = subscribing_list_id
    end

    def run
      return if Rails.env.test?

      gibbon         = Gibbon::Request.new(api_key: Rails.application.secrets.mailchimp[:api_key])
      mdhashed_email = Digest::MD5.hexdigest(email)

      begin
        potential_user = gibbon.lists(list_id).members(mdhashed_email).retrieve

        body = {
          email_address: potential_user.body["email_address"],
          status: "subscribed",
          merge_fields: potential_user.body["merge_fields"]
        }

        # subscribe user/member to the new list
        gibbon.lists(subscribing_list_id).members.create(body: body)

        # unsubscribe from old list
        gibbon.lists(list_id).members(mdhashed_email).update(body: { status: "unsubscribed" })
      rescue Gibbon::MailChimpError => e
        if ["Resource Not Found", "Member Exists"].include? e.title
          log_error(e)
        else
          notify_error(e)
        end

        return nil
      end
    end

    def self.process_all_lists(email)
      service = self.new(
        Rails.application.secrets.mailchimp[:list][:potential_customers],
        email,
        Rails.application.secrets.mailchimp[:list][:agentbright_users]
      )
      service.delay.run

      service = self.new(
        Rails.application.secrets.mailchimp[:list][:agentbright_partial_assessment],
        email,
        Rails.application.secrets.mailchimp[:list][:agentbright_users]
      )
      service.delay.run

      service = self.new(
        Rails.application.secrets.mailchimp[:list][:agentbright_assessment],
        email,
        Rails.application.secrets.mailchimp[:list][:agentbright_users]
      )
      service.delay.run
    end

    private

    def log_error(error)
      Rails.logger.info "MailchimpApi::UpdateMemberListService -> '#{error.title}'"\
        " for list_id: '#{list_id}', email: '#{email}', subscribing_list_id: '#{subscribing_list_id}'"
    end

    def notify_error(error)
      message        = "MailchimpApi::UpdateMemberListService -> ERROR: #{error.message}"
      event_metadata = error.raw_body

      Rails.logger.info message

      Honeybadger.notify(
        error_message: message,
        error_class: "MailchimpApi::UpdateMemberListService",
        parameters: event_metadata
      )

      AdminMailer.notify_stripe_event_error(message, event_metadata).deliver
    end

  end

end
