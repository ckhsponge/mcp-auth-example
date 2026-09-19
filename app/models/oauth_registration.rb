require 'faraday'

class OauthRegistration < ApplicationRecord
  serialize :redirect_uris, type: Array, coder: JSON

  attr_accessor :verified_redirect_uri, :authorize_params

  validates :client_id, presence: true, uniqueness: true,
            format: { with: /\A[a-zA-Z0-9]+\z/, message: "must be alphanumeric" }

  # Returns an OauthRegistration (unsaved for CIMD, persisted for DCR)
  # Raises ArgumentError with a message on any validation failure
  def verified_oauth_data
    {
      authorization_code: SecureRandom.urlsafe_base64(32),
      client_id: authorize_params[:client_id],
      redirect_uri: verified_redirect_uri,
      code_challenge: authorize_params[:code_challenge],
      code_challenge_method: authorize_params[:code_challenge_method],
      resource: authorize_params[:resource],
      expires_at: (Time.now + 10.minutes).to_i
    }
  end

  def self.verify_authorize(params)
    client_id = params[:client_id]
    redirect_uri = params[:redirect_uri]

    if client_id.start_with?('https://')
      begin
        response = Faraday.new(request: { timeout: 6 }).get(client_id)
        raise ArgumentError, "Failed to fetch client metadata" unless response.success?
        metadata = JSON.parse(response.body)
        raise ArgumentError, "client_id mismatch" unless metadata['client_id'] == client_id
        redirect_uris = metadata['redirect_uris'] || []
        raise ArgumentError, "redirect_uri not allowed for this client" unless redirect_uris.is_a?(Array) && redirect_uris.include?(redirect_uri)
        reg = new(
          client_id: client_id,
          client_name: metadata['client_name'],
          logo_uri: metadata['logo_uri'],
          client_uri: metadata['client_uri'],
          redirect_uris: redirect_uris
        )
        reg.verified_redirect_uri = redirect_uri
        reg.authorize_params = params
        reg
      rescue Faraday::TimeoutError
        raise ArgumentError, "Client metadata fetch timed out"
      rescue JSON::ParserError
        raise ArgumentError, "Invalid client metadata JSON"
      rescue ArgumentError
        raise
      rescue => e
        raise ArgumentError, "Failed to fetch client metadata: #{e.message}"
      end
    else
      registration = find_by(client_id: client_id)
      raise ArgumentError, "Unknown client_id" unless registration
      raise ArgumentError, "redirect_uri not allowed for this client" unless registration.redirect_uris.include?(redirect_uri)
      registration.verified_redirect_uri = redirect_uri
      registration.authorize_params = params
      registration
    end
  end
end
