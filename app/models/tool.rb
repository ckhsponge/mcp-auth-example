require_relative '../../app/network'

class Tool
  def self.mcp_text_result(text)
    {
      "content" => [
        {
          "type" => "text",
          "text" => text
        }
      ],
      "isError" => false
    }
  end

  def self.call_api(tool_name, input, auth_header)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => auth_header,
      'BEARER_VERIFIED_AT' => Time.now.utc.iso8601
    }.compact
    body = Network.post(ENV['API_URL'], { tool_name: tool_name, input: input }.to_json, headers)
    mcp_text_result(body)
  end

  def self.handle(agentcore_gateway_id, tool_target_identifier, event, auth_header: nil)
    return call_api(tool_target_identifier, event, auth_header) if ENV['API_URL']
    mcp_text_result("The current date and time is #{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S UTC')}.")
  end

  def self.handle_user(user_id, user_oauth_identifier, tool_target_identifier, event, auth_header: nil)
    # use user_id and oauth identifier to get authenticated user
    #     user_oauth = UserOauth.find_by(user_id: user_id, identifier: user_oauth_identifier)
    #     raise ArgumentError, "no user_oauth found for user_id #{user_id} and identifier #{user_oauth_identifier}" unless user_oauth

    return call_api(tool_target_identifier, event, auth_header) if ENV['API_URL']
    mcp_text_result("The current date and time is #{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S UTC')}.")
  end
end
