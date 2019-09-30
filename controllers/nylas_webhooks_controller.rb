class NylasWebhooksController < ActionController::Base

  def incoming
    json = json_from_request

    if !valid_request?(json, request.env["HTTP_X_NYLAS_SIGNATURE"])
      Rails.logger.warn "Nylas request is unauthorized"
      head :unauthorized and return
    end

    data = JSON.parse(json, symbolize_names: true)

    deltas = Nylas::Deltas.new(**data)
    Rails.logger.info "[NYLAS.webhooks] Webhook received. Deltas: #{deltas.count}"

    if deltas.present?
      NylasApi::WebhookDeltasProcessingService.new(deltas).delay.process
    end

    head :ok
  end

  def verification
    Rails.logger.info "[NYLAS.webhooks] Verification received: #{params}"
    render json: params["challenge"], status: 200
  end

  private

  def json_from_request
    request.body.rewind
    request.body.read
  end

  # Each request made by Nylas includes an X-Nylas-Signature header. The header
  # contains the HMAC-SHA256 signature of the request body, using your client
  # secret as the signing key. This allows your app to verify that the
  # notification really came from Nylas.
  def valid_request?(data, signature)
    return false if data.blank? || signature.blank?

    digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"),
                                     Rails.application.secrets.nylas[:secret],
                                     data)

    Rack::Utils.secure_compare(digest, signature)
  end

end
