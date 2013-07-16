#require 'sinatra/base'
require 'sinatra'
require 'net/http'
require 'json'
require 'uri'
 
require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-sqlite-adapter'
require 'dm-migrations'

DataMapper.setup :default, "sqlite://#{Dir.pwd}/database.db"
class CachedFile
        include DataMapper::Resource
        property :id , Serial
        property :name , Integer
        property :jsonFile , Text
        property :description , Text
        property :frequency , String
      end
DataMapper.finalize.auto_upgrade!

get '/' do
  @all_files = CachedFile.all
  
  erb :index
end

post '/' do
  
  boom = CachedFile.first(:name => params[:seriesNumber])
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

  erb :index
end

get '/graphview/:name' do  
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

post '/clear' do
  CachedFile.all.destroy
  redirect "/"
end

get '/delete/:name' do
  @name = params[:name]
  rFile = CachedFile.first(:name => "#{@name}")
  rFile.destroy
  redirect "/"
  
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