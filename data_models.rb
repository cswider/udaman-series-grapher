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