

## ROUTES ##

post '/me' do
  session[:user] if Auth.retrieve_user(request)
end 


post '/sign_in' do
  puts session.to_hash.inspect
  body = request.body.read
  if body.length > 0 && JSON.is_json?(body)
    body = JSON.parse body
    user = {:username => body['username'], :password => body['password']}
    External::Settings::UNAUTH unless AuthWorker.perform_async(request, user)
  else
    External::Settings::UNAUTH 
  end
end

post '/direct/' do
  @string = request.query_string.to_s.split('?')[0]
  @body = request.body.read 
  if Auth.session_exists?(request)

    jid = APIWorker.perform_async(@string, @body)

    fiber = Fiber.new do
      Fiber.yield API.redis(jid)
    end
    fiber.resume

    #TODO: is eval a risk here?
    

  else
    External::Settings::UNAUTH
  end
end 

post '/sign_out' do
  puts session.to_hash.inspect
  Auth.invalidate_session(request, response)
  false
end

