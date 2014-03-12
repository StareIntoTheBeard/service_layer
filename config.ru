require "rubygems"
require "sinatra"
require 'sidekiq'

require File.expand_path '../start.rb', __FILE__
require File.expand_path '../worker.rb', __FILE__
require File.expand_path '../routes.rb', __FILE__


Sidekiq.configure_server do |config|
  config.redis = { :url => 'redis://localhost:9372/' }
end

require 'sidekiq/web'
run Rack::URLMap.new('/' => Sinatra::Application, '/sidekiq' => Sidekiq::Web)