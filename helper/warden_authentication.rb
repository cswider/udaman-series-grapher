class MyApp < Sinatra::Base
  configure :production, :development do
    enable :logging
  end
  post '/unauthenticated' do
    redirect '/login'
  end
end

use Rack::Session::Cookie

use Warden::Manager do |manager|
  manager.default_strategies :password
  manager.failure_app = MyApp
  manager.serialize_into_session {|user| user.id}
  manager.serialize_from_session {|id| SavedUser.first(:id => id)}
end
 
def authenticate!
        user = SavedUser.first(:user => params["email"])
        if user && user.password == params["password"]
          success!(user)
        else
          fail!("Could not log in")
        end
end

Warden::Manager.before_failure do |env,opts|
    env['REQUEST_METHOD'] = 'POST'
  end
  
def warden_handler
    env['warden']
end

def current_user
    warden_handler.user
end

def check_authentication
    redirect '/login' unless warden_handler.authenticated?
end