# frozen_string_literal: true

require_relative 'application'

class GatewayHandler
  def self.handle(event:, context:)
    ppj "EVENT", event
    ppj "CONTEXT", context

    propagated_headers = context.client_context&.dig('custom', 'bedrockAgentCorePropagatedHeaders') || {}
    token_payload_json = propagated_headers['TokenPayload']
    token_payload = token_payload_json ? JSON.parse(token_payload_json) : {} rescue {}
    user_id = token_payload['user_id']
    user_oauth_identifier = token_payload['user_oauth_identifier']

    ppj "USER_ID", user_id
    ppj "USER_OAUTH_IDENTIFIER", user_oauth_identifier

    tool_target_identifier = context.client_context&.dig('custom', 'bedrockAgentCoreToolName')
    agentcore_gateway_id = context.client_context&.dig('custom', 'bedrockAgentCoreGatewayId')
    ppj "TOOL NAME LONG", tool_target_identifier

    result = if user_id.present? && user_oauth_identifier.present?
      Tool.handle_user(user_id, user_oauth_identifier, tool_target_identifier, event)
    else
      Tool.handle(agentcore_gateway_id, tool_target_identifier, event)
    end

    ppj "RESULT", result
    result
  rescue => e
    puts "ERROR: #{e.message}"
    puts e.backtrace
    raise
  end
end
