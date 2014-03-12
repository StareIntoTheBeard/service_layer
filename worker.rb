require './start.rb'
class APIWorker
  
  include Sidekiq::Worker

  def perform(url, body)
    results = API.pass_call(API.pc_url(url), body).force_encoding('UTF-8')
    output = Hash(:jid => self.jid, :results => results)
    Sidekiq.redis do |c|
      c.lpush('results', output )
    end
  end
end

class AuthWorker
  include Sidekiq::Worker
  def perform(request, user)
    Auth.put_session(request, user)
  end
end