require 'jwt'

# In-memory store keyed by authorization_code (the encrypted deterministic field)
# and by user_id for uniqueness.
class UserOauth
  attr_accessor :user_id, :data, :identifier, :authorization_code

  @@store = {} # keyed by authorization_code
  @@by_user = {} # keyed by user_id

  def initialize(user_id:)
    @user_id = user_id
    @data = {}
    @identifier = SecureRandom.alphanumeric(24)
    @authorization_code = nil
  end

  def user
    User.find(@user_id)
  end

  def data_indifferent
    (@data || {}).with_indifferent_access
  end

  def data_will_change!; end

  def save
    set_authorization_code
    @@by_user[@user_id] = self
    @@store[@authorization_code] = self if @authorization_code.present?
    true
  end

  def reset_identifier!
    @identifier = SecureRandom.alphanumeric(24)
    save
  end

  def generate_bearer_token(expiration = 1.year, reset_identifier: false)
    reset_identifier! if reset_identifier
    jwt(expiration)
  end

  def self.find_by(authorization_code:)
    @@store[authorization_code]
  end

  def self.create!(user:)
    obj = new(user_id: user.id)
    obj.save
    obj
  end

  def self.jwk
    pem = EnvironmentParameters[:agentcore_gateway_pem]
    raise "agentcore_gateway_pem is not configured" unless pem.present?
    optional_parameters = { kid: 'root-gateway', use: 'sig', alg: 'RS512' }
    ::JWT::JWK.new(OpenSSL::PKey::RSA.new(pem), optional_parameters)
  end

  def jwt(expiration = 1.year)
    now = Time.now.utc.to_i
    jwk = UserOauth.jwk
    return nil unless jwk
    payload = {
      "sub": "user-#{user_id}",
      "user_id": user_id,
      "user_oauth_identifier": identifier,
      "token_use": "access",
      "scope": EnvironmentParameters[:agentcore_gateway_token_scope],
      "auth_time": now,
      "iss": Constants::BASE_URL,
      "exp": (now + expiration).to_i,
      "iat": now,
      "version": 2,
      "jti": SecureRandom.uuid,
      "client_id": EnvironmentParameters[:agentcore_gateway_client_id]
    }
    ::JWT.encode(payload, jwk.signing_key, jwk[:alg], kid: jwk[:kid])
  end

  def self.jwks_as_json
    ::JWT::JWK::Set.new([jwk]).export
  end

  private

  def set_authorization_code
    code = data&.dig(:authorization_code) || data&.dig('authorization_code')
    if code.present?
      @@store.delete(@authorization_code) if @authorization_code.present?
      @authorization_code = code
    end
  end
end
