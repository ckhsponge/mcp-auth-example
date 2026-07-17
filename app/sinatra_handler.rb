# frozen_string_literal: true

require 'json'
require 'rack'
require 'base64'

$app ||= Rack::Builder.parse_file("#{__dir__}/config.ru")
ENV['RACK_ENV'] ||= 'production'

class SinatraHandler
  def self.build_query_string(params)
    params.map do |key, values|
      Array(values).map { |value| "#{key}=#{CGI.escape value.to_s}" }
    end.flatten.join('&')
  end

  def self.handle(event:, context:)
    body = if event['isBase64Encoded']
             Base64.decode64 event['body']
           else
             event['body']
           end || ''

    headers = event.fetch 'headers', {}

    env = {
      'REQUEST_METHOD' => event.fetch('httpMethod'),
      'SCRIPT_NAME' => '',
      'PATH_INFO' => event.fetch('path', ''),
      'QUERY_STRING' => build_query_string(event['multiValueQueryStringParameters'] || {}),
      'SERVER_NAME' => headers.fetch('Host', 'localhost'),
      'SERVER_PORT' => headers.fetch('X-Forwarded-Port', 443).to_s,
      "CONTENT_TYPE" => (event["headers"] || {})["Content-Type"],
      'rack.release' => Rack::RELEASE,
      'rack.url_scheme' => headers.fetch('CloudFront-Forwarded-Proto') { headers.fetch('X-Forwarded-Proto', 'https') },
      'rack.input' => StringIO.new(body),
      'rack.errors' => $stderr,
    }

    headers.each_pair do |key, value|
      name = key.upcase.gsub '-', '_'
      header = case name
               when 'CONTENT_TYPE', 'CONTENT_LENGTH' then name
               else "HTTP_#{name}"
               end
      env[header] = value.to_s
    end

    begin
      status, headers, body = $app.call env

      body_content = "".b
      body.each { |item| body_content += item.to_s.b }

      content_type_header = headers['Content-Type'] || headers['content-type'] || ''
      is_binary_response = !content_type_header.start_with?('text/', 'application/json', 'application/javascript', 'application/xml')

      response = {
        'statusCode' => status,
        'headers' => headers,
        'body' => is_binary_response ? Base64.strict_encode64(body_content) : body_content.force_encoding('UTF-8'),
        'isBase64Encoded' => is_binary_response
      }
      if event['requestContext'].has_key?('elb')
        response['isBase64Encoded'] = is_binary_response
      end
    rescue Exception => exception
      puts exception.message
      puts exception.backtrace
      response = {
        'statusCode' => 500,
        'headers' => { 'Content-Type' => 'application/json' },
        'body' => { error: exception.message }.to_json
      }
    end

    response
  end
end
