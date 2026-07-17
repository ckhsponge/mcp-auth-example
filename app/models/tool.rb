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

  def self.handle(agentcore_gateway_id, tool_target_identifier, event)
    mcp_text_result("The current date and time is #{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S UTC')}.")
  end

  def self.handle_user(user_id, user_oauth_identifier, tool_target_identifier, event)
    mcp_text_result("The current date and time is #{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S UTC')}.")
  end
end
