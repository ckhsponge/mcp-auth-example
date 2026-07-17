class BaseController < Sinatra::Application

  configure :development do
    set :host_authorization, { permitted_hosts: [] }
  end

  def development?
    Sinatra::Base.development?
  end

  set :root, APP_ROOT
  set :views, Proc.new { File.join(root, 'views') }
  set :raise_errors, false

  SESSION_COOKIE_KEY = 'rack.session'
  COOKIE_OPTIONS = {
    key: SESSION_COOKIE_KEY,
    httponly: true,
    same_site: :lax,
    secure: true,
    expire_after: 2592000 * 12 * 5,
    secret: ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
  }

  cookie_options = COOKIE_OPTIONS.dup
  cookie_options.delete(:secure) if Sinatra::Base.development?
  use Rack::Session::Cookie, cookie_options

  set :port, (ENV['RACK_ENV'] == 'production' ? 80 : 9293)

  before do
    cache_control "no-cache, no-store, private", max_age: 0
  end

  SESSION_KEY_USER = :current_user

  def current_user
    return nil unless session[SESSION_KEY_USER].present?
    @current_user ||= User.find_by(id: session[SESSION_KEY_USER])
  end

  def sign_in(user)
    return unless user
    session[SESSION_KEY_USER] = user.id
  end

  def sign_out
    @current_user = nil
    session[SESSION_KEY_USER] = nil
  end

  def halt_json(code, response = {})
    code_numeric = 400
    (code_numeric = Rack::Utils.status_code(code)) rescue ArgumentError
    response =
      if response.is_a?(Hash) && response.present?
        response
      elsif response.blank? && code&.is_a?(Symbol)
        { error: code.to_s.titleize }
      elsif response.blank?
        { error: "Unspecified Error" }
      else
        { error: response.to_s }
      end
    halt code_numeric, { 'Content-Type' => 'application/json' }, response.to_json
  end
end
