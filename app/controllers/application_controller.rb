class ApplicationController < BaseController
  def authenticate_user!
    if request.xhr? || request.content_type == 'application/json'
      halt_json(:unauthorized) unless current_user
    else
      redirect '/login' unless current_user
    end
  end

  def set_oauth_headers
    headers['Access-Control-Allow-Origin'] = request.env['HTTP_ORIGIN'] || '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, mcp-protocol-version'
    headers['Access-Control-Allow-Credentials'] = 'true'
  end
end
