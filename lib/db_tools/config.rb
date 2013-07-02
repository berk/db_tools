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

require 'fileutils'
require 'yaml'
require 'pp'

CONFIG_PATH = File.join(ENV['HOME'],'.config','dbtools')

class DbTools::Config

    def self.config
      @config ||= begin
        unless File.exists?("#{CONFIG_PATH}/config.yml") 
          FileUtils.mkdir_p(CONFIG_PATH)
          template('templates/config.yml', "#{CONFIG_PATH}/config.yml")
        end
        YAML.load(File.read("#{CONFIG_PATH}/config.yml"))
      end
    end

    def self.update_config
      File.open("#{CONFIG_PATH}/config.yml", "w") do |f|
        f.write(config.to_yaml)
      end        
    end

    def self.defaults
      config["default"]
    end

    def self.connections
      @connections ||= begin
        cons = []
        config["connections"].each do |key, settings|
          cons << DbTools::Models::Connection.new(settings.merge(:name => key))
        end
        cons
      end
    end

    def self.connection(key = nil)
      key ||= defaults["connection"]
      DbTools::Models::Connection.new(config['connections'][key].merge(:name => key))
    end

end
