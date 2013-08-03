def loginToUdaman
  
  agent = Mechanize.new 
  page = agent.get("http://udaman.uhero.hawaii.edu/users/sign_in")
  dashboard = page.form_with(:action => '/users/sign_in') do |f|
    f.send("user[email]=", 'USER_EMAIL')
    f.send("user[password]=", 'USER_PASSWORD')
  end.click_button
  
end

def getJsonStringFromUdaman(seriesNum)
  
  @json_string = agent.get("http://udaman.uhero.hawaii.edu/series/#{seriesNum}.json").body
  @json_data = JSON.parse(@json_string)
  @desc = @json_data["description"]
  @freq = @json_data["frequency"]
  
end