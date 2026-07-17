class WellKnownController < ApplicationController

  before do
    set_oauth_headers
  end

  options '/*' do
    200
  end

  get '/openid-configuration' do
    base_url = Constants::BASE_URL
    json({
      authorization_endpoint: "#{base_url}/oauth/authorize",
      end_session_endpoint: "#{base_url}/logout",
      id_token_signing_alg_values_supported: ["RS256"],
      issuer: base_url,
      jwks_uri: "#{base_url}/.well-known/jwks.json",
      response_types_supported: ["code", "token"],
      revocation_endpoint: "#{base_url}/oauth/revoke",
      scopes_supported: ["openid", "email", "phone", "profile"],
      subject_types_supported: ["public"],
      token_endpoint: "#{base_url}/oauth/token",
      token_endpoint_auth_methods_supported: ["client_secret_basic", "client_secret_post"],
      userinfo_endpoint: "#{base_url}/oauth/user_info"
    })
  end

  get '/jwks.json' do
    json UserOauth.jwks_as_json
  end

  get '/oauth-authorization-server' do
    base_url = ENV.fetch('OAUTH_AUTHORIZATION_SERVER', "#{Constants::BASE_URL}/oauth")
    json({
      issuer: base_url,
      authorization_endpoint: "#{base_url}/authorize",
      token_endpoint: "#{base_url}/token",
      registration_endpoint: "#{base_url}/register",
      response_types_supported: ["code"],
      response_modes_supported: ["query"],
      grant_types_supported: ["authorization_code", "refresh_token"],
      token_endpoint_auth_methods_supported: ["client_secret_basic", "client_secret_post", "none"],
      revocation_endpoint: "#{base_url}/token",
      code_challenge_methods_supported: ["plain", "S256"]
    })
  end
end
