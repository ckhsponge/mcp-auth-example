require_relative 'spec_helper'

RSpec.describe ApiController do
  include Rack::Test::Methods

  def app = ApiController

  def auth_header(token)
    { 'HTTP_AUTHORIZATION' => "Bearer #{token}" }
  end

  def sig_headers(token, secret)
    timestamp = Time.now.utc.iso8601
    digest = OpenSSL::HMAC.hexdigest('SHA256', secret, "#{token}:#{timestamp}")
    {
      'HTTP_AUTHORIZATION'      => "Bearer #{token}",
      'HTTP_BEARER_VERIFIED_AT' => timestamp,
      'HTTP_X_SIGNATURE'        => digest
    }
  end

  describe 'POST /tool_call' do
    context 'with a valid token' do
      let(:token) { TokenHelper.generate_token }

      it 'returns 200 with tool_name, input, random, and sub' do
        post '/tool_call', { tool_name: 'echo', input: 'hello' }, auth_header(token)
        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)
        expect(body['tool_name']).to eq('echo')
        expect(body['input']).to eq('hello')
        expect(body['random']).to be_a(Integer)
        expect(body['sub']).to eq('user-1')
      end
    end

    context 'with API_DIGEST_SECRET set' do
      let(:token)  { TokenHelper.generate_token }
      let(:secret) { 'testsecret' }

      around { |ex| with_env('API_DIGEST_SECRET' => secret) { ex.run } }

      it 'returns 200 with a valid signature' do
        post '/tool_call', { tool_name: 'echo', input: 'hello' }, sig_headers(token, secret)
        expect(last_response.status).to eq(200)
      end

      it 'returns 401 with a wrong signature' do
        headers = sig_headers(token, secret).merge('HTTP_X_SIGNATURE' => 'a' * 64)
        post '/tool_call', { tool_name: 'echo', input: 'hello' }, headers
        expect(last_response.status).to eq(401)
      end

      it 'returns 401 with a missing signature' do
        headers = sig_headers(token, secret).tap { |h| h.delete('HTTP_X_SIGNATURE') }
        post '/tool_call', { tool_name: 'echo', input: 'hello' }, headers
        expect(last_response.status).to eq(401)
      end

      it 'returns 401 with a mismatched timestamp' do
        headers = sig_headers(token, secret).merge('HTTP_BEARER_VERIFIED_AT' => '2000-01-01T00:00:00Z')
        post '/tool_call', { tool_name: 'echo', input: 'hello' }, headers
        expect(last_response.status).to eq(401)
      end
    end

    context 'with no Authorization header' do
      it 'returns 401' do
        post '/tool_call', { tool_name: 'echo', input: 'hello' }
        expect(last_response.status).to eq(401)
      end
    end

    context 'with an expired token' do
      let(:token) { TokenHelper.generate_token(exp: Time.now.utc.to_i - 10) }

      it 'returns 401' do
        post '/tool_call', { tool_name: 'echo', input: 'hello' }, auth_header(token)
        expect(last_response.status).to eq(401)
      end
    end

    context 'with a wrong audience' do
      let(:token) { TokenHelper.generate_token(aud: 'https://wrong.example.com') }

      it 'returns 401' do
        post '/tool_call', { tool_name: 'echo', input: 'hello' }, auth_header(token)
        expect(last_response.status).to eq(401)
      end
    end
  end
end
