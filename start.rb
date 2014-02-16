require 'sinatra'
require 'thin'
require 'json'
require "net/http"
require "uri"
require "pg"
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :expire_after => 2592000,
                           :secret => 'put_a_bird_on_it'

#TODO: come up with a real solution to this
set :protection, :except => [:http_origin]

before do

  unless ['/sign_in', 'sign_out'].include? request.path_info 
    External::Settings::UNAUTH unless Auth.session_exists?(request)
  end

end

module JSON

  def self.is_json?(thing)
    begin
      false unless thing.is_a?(String)
      JSON.parse(thing).all?
    rescue JSON::ParserError
      false
    end 
  end

end

class External

  class Settings 
  
    #DB Config
    DATABASE = 'jbean'
    DBUSER = 'jbean'
    DBHOST = 'localhost'
    DBPW = ''
    
    #URLs
    PCBase = 'http://localhost:3080'
    AuthBase = 'http://localhost:8080/auth'

    #Statuses
    UNAUTH = 401, 'Unauthorized'
  
  end 

  def self.query(query)
    conn = PG::Connection.open( :host => External::Settings::DBHOST, 
                                :user => External::Settings::DBUSER, 
                                :dbname => External::Settings::DATABASE )
    conn.exec_params(query)
  end

end


class Auth 

  def self.session_exists?(request)
    true unless request.session['session_id'] == nil && request.session['user'] == nil
  end

  def self.put_session(request, user)
    request.session['user'] = user[:username]
    userfind = External.query("SELECT 1 FROM users WHERE username = '#{user[:username]}' AND password = '#{user[:password]}';")
    if userfind.cmd_tuples == 1
      request.session[:init] = true unless session_exists?(request)
      request.session[:user] = userfind.getvalue(0,0)
      true
    else 
      false
    end
  end

  def self.invalidate_session(request)
    request.session.delete(:user)
    request.session.delete(:init)
    request.session.delete(:session_id)
  end


  def self.retrieve_user(request)
    if request.session[:user]
      userfind = External.query("SELECT 1 FROM users WHERE id = '#{request.session[:user]}';")
      if userfind.cmd_tuples == 1
        request.session[:init] = true unless session_exists?(request)
        request.session[:user] = userfind.getvalue(0,0)
        true
      else 
        false
      end
    else
      External::Settings::UNAUTH
    end
  end

end

class API

  def self.pass_call(url, body)
    if JSON.is_json?(body)
      Net::HTTP.post_form(url, JSON.parse(body)).value
    elsif body == ''
      Net::HTTP.get(url)
    else
      External::Settings::UNAUTH
    end
  end

  def self.pc_url(route)
    URI.parse(External::Settings::PCBase+route.to_s)
  end

  def self.auth_url(route = nil)
    URI.parse(External::Settings::AuthBase+route.to_s)
  end

end

## ROUTES ##

post '/me' do
  session[:user] if Auth.retrieve_user(request)
end 


post '/sign_in' do
  body = request.body.read
  if body.length > 0 && JSON.is_json?(body)
    body = JSON.parse body
    user = {:username => body['username'], :password => body['password']}
    External::Settings::UNAUTH unless Auth.put_session(request, user)
  else
    External::Settings::UNAUTH 
  end
end

post '/direct/' do
  @string = request.query_string.to_s.split('?')
  @string = @string[0]
  @body = request.body.read 
  if Auth.session_exists?(request)
      API.pass_call(API.pc_url(@string), @body)
  else
    External::Settings::UNAUTH
  end
end 

post '/sign_out' do
  Auth.invalidate_session(request)
  false
end

