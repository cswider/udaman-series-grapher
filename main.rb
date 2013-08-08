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

load 'warden_authentication.rb'
load 'mechanize_udaman_login.rb'

DataMapper.setup(:default, ENV['DATABASE_URL'] ||  DATABASE_INFORMATION)

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

class Annotation
      include DataMapper::Resource
      property :id , Serial
      property :series , Integer
      property :date , Integer
      property :message , Text, :lazy => false
end

DataMapper.finalize.auto_upgrade!

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

post '/annotation/add/:series' do
  check_authentication
  
  @series = params[:series]
  date = params[:annotation_date]
  @message = params[:annotation_message]
  arrayDate = []
  
  tFile = CachedFile.first(:name => "#{@series}")
  cached_json = JSON.parse(tFile.jsonFile)
  cached_json["data"].each do |date, data|
    arrayDate.push(date)
  end
  
  # date_hash = Hash[arrayDate.map.with_index.to_a]
  # @date_num = date_hash[date]
  
  @date_num = arrayDate("#{date}")
  
  sFile = Annotation.new series: @series, date: 20, message: @message
  sFile.save
  
  redirect "/admin/graphview/#{@series}"
end

get '/admin/modify' do
  check_authentication
  
  @all_accounts = SavedUser.all
  @all_accounts.shift
  
  erb :add_admin
end

post '/admin/modify' do
  check_authentication
  
  user = SavedUser.new user: params[:email], password: params[:password]
  user.save
  
  @all_accounts = SavedUser.all
  @all_accounts.shift

  erb :add_admin
end

get '/deleteaccount/:name' do
  check_authentication
  
  @user = params[:name]
  c_user = SavedUser.first(:id => "#{@user}")
  c_user.destroy
  
  redirect "/admin/modify"
end

post '/admin/cache' do
  check_authentication
  
  boom = CachedFile.all(:name => params[:seriesNumber])
  boom.destroy unless boom.nil?
  DataMapper.auto_upgrade! 
  
  require 'mechanize'
  
  loginToUdaman
  
  getJsonStringFromUdaman(params[:series])
  
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

  loginToUdaman
  
  getJsonStringFromUdaman(params[:series])
  
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
  
  @annotations = Annotation.all(:series => "#{@name}")
  
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
  
  @annotations = Annotation.all(:series => "#{@name}")
  
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
  @callback = nil
  @cached_json = rFile.jsonFile
  
  erb :json
end

get '/json/:name/:callback' do
  content_type 'application/javascript'
  
  @name = params[:name]
  rFile = CachedFile.first(:name => "#{@name}")
  
  
  @callback = params[:callback]
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