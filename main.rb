require 'sinatra'
require 'net/http'
require 'json'
require 'uri'
require 'pg'
 
require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-postgres-adapter'
require 'dm-migrations'

require 'warden'


class MyApp < Sinatra::Base
  configure :production, :development do
    enable :logging
  end
  post '/unauthenticated' do
    redirect '/login'
  end
end

DataMapper.setup(:default, ENV['DATABASE_URL'] ||  "postgres://esoihoycwhxzma:SMmGZV-7ZLpokE8pncJa7-aud1@ec2-54-225-68-241.compute-1.amazonaws.com/d62n1cs47o6lpt")

class CachedFile
      include DataMapper::Resource
      property :id , Serial
      property :name , Integer
      property :jsonFile , Text
      property :description , Text
      property :frequency , String
end
      
class SavedUser
      include DataMapper::Resource
      property :id , Serial
      property :user , String
      property :password , String
end

class RequestSeries
      include DataMapper::Resource
      property :id , Serial
      property :series , Integer
end
      
DataMapper.finalize.auto_upgrade!



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

get '/' do
  @all_files = CachedFile.all
  
  erb :index
end

get '/cachedjson' do
  content_type 'application/javascript'
  
  @jsonList = {}
  
  require 'json'
  
  files = CachedFile.all
  files.each do |f|
    @jsonList.store(f.name, f.description)
  end
    
  erb :jsonList
end

post '/admin/cache' do
  check_authentication
  
  boom = CachedFile.all(:name => params[:seriesNumber])
  boom.destroy unless boom.nil?
  DataMapper.auto_upgrade! 
  
  require 'mechanize'
  
  agent = Mechanize.new 
  page = agent.get("http://udaman.uhero.hawaii.edu/users/sign_in")
  dashboard = page.form_with(:action => '/users/sign_in') do |f|
    f.send("user[email]=", 'cdouglas14@punahou.edu')
    f.send("user[password]=", 'ud@m@n')
  end.click_button
  
  @json_string = agent.get("http://udaman.uhero.hawaii.edu/series/#{params[:seriesNumber]}.json").body
  @json_data = JSON.parse(@json_string)
  @desc = @json_data["description"]
  @freq = @json_data["frequency"]
  
  file = CachedFile.new name: params[:seriesNumber], jsonFile: @json_string, description: @desc, frequency: @freq
  file.save
  
  @all_files = CachedFile.all
  @all_requests = RequestSeries.all

  erb :admin
end

get '/admin/cacherequest/:series' do
  check_authentication
  
  boom = RequestSeries.all(:series => params[:series])
  boom.destroy unless boom.nil?
  boom2 = CachedFile.all(:name => params[:series])
  boom2.destroy unless boom.nil?
  DataMapper.auto_upgrade!
      
  require 'mechanize'

  agent = Mechanize.new
  page = agent.get("http://udaman.uhero.hawaii.edu/users/sign_in")
  
  dashboard = page.form_with(:action => '/users/sign_in') do |f|
    f.send("user[email]=", 'cdouglas14@punahou.edu')
    f.send("user[password]=", 'ud@m@n')
  end.click_button
  
  @json_string = agent.get("http://udaman.uhero.hawaii.edu/series/#{params[:series]}.json").body
  @json_data = JSON.parse(@json_string)
  @desc = @json_data["description"]
  @freq = @json_data["frequency"]
  
  file = CachedFile.new name: params[:series], jsonFile: @json_string, description: @desc, frequency: @freq
  file.save
  
  @all_files = CachedFile.all
  @all_requests = RequestSeries.all

  redirect '/admin' 
end

get '/deleterequest/:series' do
  check_authentication
  
  @series = params[:series]
  request = RequestSeries.first(:series => "#{@series}")
  request.destroy
  
  redirect "/admin"
end

get '/admin' do
  check_authentication

  @all_files = CachedFile.all
  @all_requests = RequestSeries.all

  erb :admin
end

get '/graphview/:name' do  
  
  @all_files = CachedFile.all
  @array = []
  @arrayDate = []
  
  @name = params[:name]
  rFile = CachedFile.first(:name => "#{@name}")
  @chartHeader = rFile.description
  @cached_json =  JSON.parse(rFile.jsonFile)
  
  @cached_json["data"].each do |date, data|
    @array.push(data)
    @arrayDate.push(date)
  end
  
  erb :graphview
end

get '/admin/graphview/:name' do  
  check_authentication
  
  @all_files = CachedFile.all
  @all_requests = RequestSeries.all
  @array = []
  @arrayDate = []  
  
  @name = params[:name]
  rFile = CachedFile.first(:name => "#{@name}")
  @chartHeader = rFile.description
  @cached_json =  JSON.parse(rFile.jsonFile)
  
  @cached_json["data"].each do |date, data|
    @array.push(data)
    @arrayDate.push(date)
  end
  
  erb :adminGraph
end

post '/request' do
  
  request = RequestSeries.new series: params[:seriesRequest]
  request.save
  
  redirect '/'
end

post '/clear' do
  check_authentication
  
  CachedFile.all.destroy
  
  redirect "/admin"
end

post '/clearrequests' do
  check_authentication
  
  RequestSeries.all.destroy
  
  redirect "/admin"
end

get '/delete/:name' do
  
  check_authentication
  
  @name = params[:name]
  rFile = CachedFile.first(:name => "#{@name}")
  rFile.destroy
  
  redirect "/admin"
end

get '/json/:name' do
  content_type 'application/javascript'
  
  @name = params[:name]
  rFile = CachedFile.first(:name => "#{@name}")
  
  @cached_json = rFile.jsonFile
  
  erb :json
end

get '/embed/:name' do
  
  @name = params[:name]
  @seriesName = @name
  
  erb :embed
end 

get '/login' do
  erb :login
end

post '/session' do 
  warden_handler.authenticate!
  if warden_handler.authenticated?
    redirect "/admin" 
  else
    redirect "/login"
  end
end

post '/unauthenticated' do
  redirect '/'
end

get '/logout' do
    warden_handler.logout
    redirect '/'
end