require 'sinatra'
require 'rest_client'
require 'slim'

get '/' do
  slim :index
end

get '/mood/:from/:to/' do
  response = RestClient.get "https://openapi.project-ginsberg.com/v1/s/mood/from/#{params[:from]}/to/#{params[:to]}", {:accept => :json}
  content_type :json      
  response
end

get '/sleep/:from/:to/' do
  response = RestClient.get "https://openapi.project-ginsberg.com/v1/o/sleep/from/#{params[:from]}/to/#{params[:to]}", {:accept => :json}
  content_type :json      
  response
end
