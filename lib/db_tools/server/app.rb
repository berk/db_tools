#--
# Copyright (c) 2013 Michael Berkovich
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

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
    erb :'/index'
  end

  post '/tree' do 
    pp params

    if params["node"] == 'connections'
      return DbTools::Config.connections.collect{|con| con.to_ext_hash}.to_json
    end

    path = params["node"].split('/')
    last = path.last.split(':')

    conn = DbTools::Config.connection(path.first.split(':').last)

    if last.first == 'table'

    end

    if last.first == 'connection'
      database = DbTools::Models::Database.init(conn)
      tables = database.tables.collect{ |table|
        table.to_ext_hash
      }
      tables.to_json
    end
  end
  
end
