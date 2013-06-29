require 'sinatra'
require 'erb'
require 'json'

class DbTools::Server::App < Sinatra::Base

  set :static, true                             # set up static file routing
  set :public_folder, File.expand_path('../public', __FILE__) # set up the static dir (with images/js/css inside)
  set :views,  File.expand_path('../views', __FILE__) # set up the views dir
  set :layout_engine => :erb
  set :json_encoder, :to_json

  get '/' do
    # @folder = PhotoOrganizer::Models::Folder.new('.')
    erb :'/index'
  end

  get '/photos' do 
    # path = ".#{params[:path]}"
    # folder = PhotoOrganizer::Models::Folder.new(path)
    # photos = folder.photos.collect{|photo| photo.to_glance_hash}
    # pp photos
    # photos.to_json
  end
  
end
