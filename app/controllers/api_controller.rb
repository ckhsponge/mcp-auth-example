class ApiController < ApplicationController
  before do
    halt_json(:unauthorized) unless bearer_payload
    verify_digest_signature!
  end

  post '/tool_call' do
    content_type :json
    { tool_name: params[:tool_name], input: params[:input], random: rand(10000), sub: bearer_payload['sub'] }.to_json
  end

  private

  def verify_digest_signature!
    return unless (secret = ENV['API_DIGEST_SECRET'])
    token = (request.env['HTTP_AUTHORIZATION'] || '').delete_prefix('Bearer ')
    timestamp = request.env['HTTP_BEARER_VERIFIED_AT'] || ''
    expected = OpenSSL::HMAC.hexdigest('SHA256', secret, "#{token}:#{timestamp}")
    received = request.env['HTTP_X_SIGNATURE'] || ''
    begin
      halt_json(:unauthorized) unless OpenSSL.fixed_length_secure_compare(expected, received)
    rescue ArgumentError # if strings are different lengths
      halt_json(:unauthorized)
    end
  end

  def bearer_payload
    @bearer_payload ||= begin
      header = request.env['HTTP_AUTHORIZATION'] || ''
      token = header.delete_prefix('Bearer ')
      return nil if token.blank?
      jwks = JWT::JWK::Set.new(UserOauth.jwks_as_json)
      JWT.decode(
        token, nil, true,
        algorithms: [EnvironmentParameters[:mcp_server_algorithm]],
        aud: EnvironmentParameters[:mcp_server_audience],
        verify_aud: true,
        jwks: jwks
      ).first
    rescue JWT::DecodeError
      nil
    end
  end
end
