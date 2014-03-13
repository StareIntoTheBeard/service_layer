require 'sinatra'
require 'thin'
require 'json'
require "net/http"
require "timerizer"
require "uri"
require "pg"
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '*',
                           :expire_after => 2592000,
                           :secret => 'put_a_bird_on_it'

#TODO: come up with a real solution to this
set :protection, :except => [:http_origin]

before do
  unless ['/sign_in', '/sign_out'].include? request.path_info 
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
    PRESIGNED = 200, 'Already signed in.'
  
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
    request.session['user'] == nil ? false : true
  end

  def self.put_session(request, user)
    userfind = External.query("SELECT 1 FROM users WHERE username = '#{user[:username]}' AND password = '#{user[:password]}';")
    if userfind.cmd_tuples == 1
      unless session_exists?(request)
        request.session[:init] = true
        request.session[:user] = userfind.getvalue(0,0)
        true
      end
    else 
      false
    end
  end

  def self.invalidate_session(request, response)
    request.session.delete(:user)
    request.session.delete(:init)
    request.session.delete(:session_id)
    response.set_cookie('rack.session', nil)  
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
    if body == ''
       Net::HTTP.get(url)
    elsif JSON.is_json?(body)
       Net::HTTP.post_form(url, JSON.parse(body)).value
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



