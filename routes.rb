

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

    results = APIWorker.perform_async(@string, @body)
   
    job = nil
    dump = nil
    limit = 0
    while job == nil
      Sidekiq.redis do |c|
        dump = c.lrange('results', 0, -1)
        job = dump.find {|e| e.include? results}
        limit += 1
        break if limit > 1000
      end
    end
    limit = 0
    job_index = dump.index(job)
    Sidekiq.redis do |c|
      c.del('results', job_index )
    end

    #TODO: is eval a risk here?
    eval(job)[:results]

  else
    External::Settings::UNAUTH
  end
end 

post '/sign_out' do
  puts session.to_hash.inspect
  Auth.invalidate_session(request, response)
  false
end

