ENV['RACK_ENV'] = 'test'

require 'dotenv'
Dotenv.load(File.expand_path('../../.env', __dir__))

require 'jwt'
require 'rack/test'
require_relative '../application'

module TokenHelper
  PEM       = ENV.fetch('MCP_SERVER_PEM')
  KID       = ENV.fetch('MCP_SERVER_KID')
  SCOPE     = ENV.fetch('MCP_SERVER_INVOKE_SCOPE')
  AUDIENCE  = ENV.fetch('MCP_SERVER_AUDIENCE')
  ALGORITHM = ENV.fetch('MCP_SERVER_ALGORITHM')

  def self.jwk
    @jwk ||= JWT::JWK.new(OpenSSL::PKey::RSA.new(PEM), { kid: KID, use: 'sig', alg: ALGORITHM })
  end

  def self.generate_token(overrides = {})
    now = Time.now.utc.to_i
    payload = {
      sub: 'user-1',
      scope: SCOPE,
      iss: Constants::BASE_URL,
      aud: AUDIENCE,
      exp: now + 3600,
      iat: now,
    }.merge(overrides)
    ::JWT.encode(payload, jwk.signing_key, ALGORITHM, kid: KID)
  end
end
