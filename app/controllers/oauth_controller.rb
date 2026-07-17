class OauthController < ApplicationController

  before do
    set_oauth_headers
  end

  options '/*' do
    200
  end

  post '/register' do
    request.body.rewind
    client_metadata = JSON.parse(request.body.read) rescue {}
    client_id = SecureRandom.uuid
    json({
      client_id: client_id,
      client_id_issued_at: Time.now.to_i,
      redirect_uris: client_metadata['redirect_uris'] || [],
      grant_types: ['authorization_code', 'refresh_token'],
      response_types: ['code'],
      token_endpoint_auth_method: 'none'
    })
  end

  get '/authorize' do
    required_params = [:response_type, :client_id, :redirect_uri, :code_challenge, :code_challenge_method]
    missing = required_params.select { |p| params[p].blank? }
    halt_json(:bad_request, "Missing parameters: #{missing.join(', ')}") if missing.any?
    halt_json(:bad_request, "Invalid response_type") unless params[:response_type] == 'code'
    halt_json(:bad_request, "Invalid code_challenge_method") unless params[:code_challenge_method] == 'S256'

    @authorize_params = params.slice(
      :response_type, :client_id, :redirect_uri,
      :code_challenge, :code_challenge_method, :resource, :state
    )

    slim :oauth_authorize
  end

  post '/authorize' do
    halt_json(:unauthorized) unless current_user

    if params[:deny] == 'true'
      redirect_uri = URI.parse(params[:redirect_uri])
      query_params = URI.decode_www_form(redirect_uri.query || '').to_h
      query_params['error'] = 'access_denied'
      query_params['state'] = params[:state] if params[:state]
      redirect_uri.query = URI.encode_www_form(query_params)
      redirect redirect_uri.to_s # halts
    end

    required_params = [:response_type, :client_id, :redirect_uri, :code_challenge, :code_challenge_method]
    missing = required_params.select { |p| params[p].blank? }
    halt_json(:bad_request, "Missing parameters: #{missing.join(', ')}") if missing.any?
    halt_json(:bad_request, "Invalid response_type") unless params[:response_type] == 'code'
    halt_json(:bad_request, "Invalid code_challenge_method") unless params[:code_challenge_method] == 'S256'

    auth_code = SecureRandom.urlsafe_base64(32)
    oauth_data = {
      authorization_code: auth_code,
      client_id: params[:client_id],
      redirect_uri: params[:redirect_uri],
      code_challenge: params[:code_challenge],
      code_challenge_method: params[:code_challenge_method],
      resource: params[:resource],
      expires_at: (Time.now + 10.minutes).to_i
    }

    user_oauth = current_user.get_or_create_user_oauth
    user_oauth.data = oauth_data
    user_oauth.data_will_change!
    halt_json(:internal_server_error, "Failed to create authorization code") unless user_oauth.save

    redirect_uri = URI.parse(params[:redirect_uri])
    query_params = URI.decode_www_form(redirect_uri.query || '').to_h
    query_params['code'] = auth_code
    query_params['state'] = params[:state] if params[:state]
    redirect_uri.query = URI.encode_www_form(query_params)
    redirect redirect_uri.to_s
  end

  post '/token' do
    halt_json(:bad_request, "Invalid grant_type") unless params[:grant_type] == 'authorization_code'

    required_params = [:code, :redirect_uri, :code_verifier]
    missing = required_params.select { |p| params[p].blank? }
    halt_json(:bad_request, "Missing parameters: #{missing.join(', ')}") if missing.any?

    user_oauth = UserOauth.find_by(authorization_code: params[:code])
    halt_json(:unauthorized, "Invalid authorization code") unless user_oauth

    oauth_data = user_oauth.data_indifferent

    if oauth_data[:expires_at] && oauth_data[:expires_at] < Time.now.to_i
      halt_json(:unauthorized, "Authorization code expired")
    end

    code_challenge = Base64.urlsafe_encode64(
      Digest::SHA256.digest(params[:code_verifier]),
      padding: false
    )
    halt_json(:unauthorized, "Invalid code_verifier") unless code_challenge == oauth_data[:code_challenge]
    halt_json(:unauthorized, "Invalid redirect_uri") unless params[:redirect_uri] == oauth_data[:redirect_uri]

    oauth_data.delete(:authorization_code)
    oauth_data.delete(:code_challenge)
    oauth_data.delete(:code_challenge_method)
    oauth_data.delete(:expires_at)
    user_oauth.data = oauth_data
    halt_json(:internal_server_error, "Failed to clear authorization code") unless user_oauth.save

    expiration = 1.year
    bearer_token = user_oauth.generate_bearer_token(expiration, reset_identifier: false)
    halt_json(:internal_server_error, "Failed to generate token") unless bearer_token

    json({
      access_token: bearer_token,
      token_type: 'Bearer',
      expires_in: expiration.to_i,
      scope: EnvironmentParameters[:root_gateway_token_scope]
    })
  end
end
