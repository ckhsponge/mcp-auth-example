APP_START = Time.now

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
ENV['TZ'] = 'UTC'

require 'bundler/setup'
require 'rack'
require 'rack/contrib'
require 'rack/contrib/post_body_content_type_parser'
require 'sinatra/base'
require 'sinatra/json'
require 'dotenv' if Sinatra::Base.development? || Sinatra::Base.test?
require 'json'
require 'ostruct'
require 'zeitwerk'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/json'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/string/inflections'

APP_ROOT = File.dirname(__FILE__)

require "#{APP_ROOT}/lib/ppj"

def development?
  Sinatra::Base.development?
end

Dotenv.load('../.env') if development?
if Sinatra::Base.test?
  Dotenv.load('../.env_test', '../.env_test_aws')
end

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/lib")
loader.push_dir("#{__dir__}/models")
loader.push_dir("#{__dir__}/helpers")
loader.push_dir("#{__dir__}/controllers")
loader.setup

LazyInitializers.load_all!

BaseController

puts "application.rb COMPLETE: #{Time.now} (duration: #{((Time.now - APP_START) * 1000).round(1)}ms)"
