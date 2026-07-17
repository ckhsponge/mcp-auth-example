module Constants
  HOST_NAME = ENV.fetch('HOST_NAME')
  PROTOCOL = ENV.fetch('PROTOCOL', development? ? 'http' : 'https')
  PORT_OVERRIDE = ENV.fetch('PORT_OVERRIDE', development? ? '9292' : nil)
  BASE_URL = HOME_URL = ["#{PROTOCOL}://#{HOST_NAME}", PORT_OVERRIDE.presence].compact.join(":")
end
