CONFIG_RU_START = Time.now

require "#{File.dirname(__FILE__)}/application"

LAZY_LOAD = ->(class_name) do
  controller = nil
  ->(env) { (controller ||= class_name.constantize).call(env) }
end

use Rack::JSONBodyParser

map("/.well-known") { run LAZY_LOAD.call('WellKnownController') }
map("/oauth")       { run LAZY_LOAD.call('OauthController') }
map("/")            { run LAZY_LOAD.call('RootController') }

CONFIG_RU_END = Time.now
puts "config.ru COMPLETE: #{CONFIG_RU_END} (duration: #{(CONFIG_RU_END - CONFIG_RU_START).round(3)}s)"
