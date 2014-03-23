require 'sinatra'
require 'rest_client'

before do
  content_type :json      
end

get '/mood/:from/:to/' do
  response = RestClient.get "https://openapi.project-ginsberg.com/v1/s/mood/from/#{params[:from]}/to/#{params[:to]}", {:accept => :json}
  response
end

get '/sleep/:from/:to/' do
  response = RestClient.get "https://openapi.project-ginsberg.com/v1/o/sleep/from/#{params[:from]}/to/#{params[:to]}", {:accept => :json}
  response
end
