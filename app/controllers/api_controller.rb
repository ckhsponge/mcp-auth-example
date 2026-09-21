class ApiController < ApplicationController
  before do
    halt_json(:unauthorized) unless bearer_payload
  end

  post '/tool_call' do
    content_type :json
    { tool_name: params[:tool_name], input: params[:input], random: rand(10000), sub: bearer_payload['sub'] }.to_json
  end

  private

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
