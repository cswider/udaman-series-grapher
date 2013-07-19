#require 'sinatra/base'
require 'sinatra'
require 'net/http'
require 'json'
require 'uri'
require 'pg'
 
require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-postgres-adapter'
#require 'dm-sqlite-adapter
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

#DataMapper.setup :default, "sqlite://#{Dir.pwd}/database.db"

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
      
DataMapper.finalize.auto_upgrade!



use Rack::Session::Cookie

use Warden::Manager do |manager|
  manager.default_strategies :password
  manager.failure_app = MyApp
  manager.serialize_into_session {|user| user.id}
  manager.serialize_from_session {|id| SavedUser.first(:id => id)}
end

Warden::Strategies.add(:password) do
  def valid?
    params["email"] || params["password"]
  end
 
  def authenticate!
        user = SavedUser.first(:user => params["email"])
        if user && user.password == params["password"]
          success!(user)
        else
          fail!("Could not log in")
        end
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

post '/admin/cache' do
  
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

  erb :admin
end

get '/admin' do
  check_authentication

  @all_files = CachedFile.all

  erb :admin
end

get '/graphview/:name' do  
  
  @all_files = CachedFile.all
  
  @name = params[:name]
  rFile = CachedFile.first(:name => "#{@name}")
  
  @cached_json =  JSON.parse(rFile.jsonFile)
  
  @array = []
       @arrayDate = []
       @cached_json["data"].each do |date, data|
         @array.push(data)
         @arrayDate.push(date)
       end
  
  erb :graphview
end

get '/admin/graphview/:name' do  
  
  check_authentication
  
  @all_files = CachedFile.all
  
  @name = params[:name]
  rFile = CachedFile.first(:name => "#{@name}")
  
  @cached_json =  JSON.parse(rFile.jsonFile)
  
  @array = []
       @arrayDate = []
       @cached_json["data"].each do |date, data|
         @array.push(data)
         @arrayDate.push(date)
       end
  
  erb :adminGraph
end

post '/clear' do
  
  check_authentication
  
  CachedFile.all.destroy
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
  @name = params[:name]
  rFile = CachedFile.first(:name => "#{@name}")
  
  @cached_json =  JSON.parse(rFile.jsonFile)
  
  erb :json
end

get '/embed/:name' do
  @name = params[:name]
  erb :embed
end 

get '/embed/:name/chart' do
  
  @name = params[:name]
  rFile = CachedFile.first(:name => "#{@name}")
  
  @cached_json =  JSON.parse(rFile.jsonFile)
  
  @array = []
       @arrayDate = []
       @cached_json["data"].each do |date, data|
         @array.push(data)
         @arrayDate.push(date)
       end

  erb :chartsolo
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