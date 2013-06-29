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
require 'thor'
require 'pp'
require 'active_record'

CONFIG_PATH = File.join(ENV['HOME'],'.config','dbtools')

class DbTools::Base < Thor
    include Thor::Actions

    protected

    def config
      @config ||= begin
        unless File.exists?("#{CONFIG_PATH}/config.yml") 
          FileUtils.mkdir_p(CONFIG_PATH)
          template('templates/config.yml', "#{CONFIG_PATH}/config.yml")
        end
        YAML.load(File.read("#{CONFIG_PATH}/config.yml"))
      end
    end

    def update_config
      File.open("#{CONFIG_PATH}/config.yml", "w") do |f|
        f.write(config.to_yaml)
      end        
    end

    def defaults
      config["default"]
    end

    def connection(key = nil)
      key ||= defaults["connection"]
      DbTools::Models::Connection.new(config['connections'][key].merge(:name => key))
    end

    def format_number(n)
      n.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse
    end

    def ask_for_number(max, opts = {})
      opts[:message] ||= "Choose: "
      while true
        value = ask(opts[:message])
        if /^[\d]+$/ === value
          num = value.to_i
          if num < 1 or num > max
            say("Hah?")
          else
            return num
          end
        else
          say("Hah?")
        end
      end
    end

    def paginate(results, opts = {})
      say
      say(opts[:header]) if opts[:header]
      say

      if results.nil? or results.size == 0
        say("None found")
        return
      end

      opts[:per_page] ||= 50
      opts[:columns]  ||= begin
        cols = []
        results.first.keys.each do |k| 
          next unless k.is_a?(String) or k.is_a?(Symbol)
          cols << k.to_sym
        end
        cols
      end

      page = 0
      while true
        table = []
        titles = []
        unless opts[:skip_title]
          if opts[:with_numbers]
            titles << ""
          end

          opts[:columns].each do |c|
            if c.is_a?(Symbol)
              titles << c.to_s
            elsif c.is_a?(Array)
              titles << c.last.to_s
            elsif c.is_a?(Hash)
              titles << c[:title].to_s
            else
              say("Invalid pagination call...")
              return
            end
          end
          table << titles
        end

        start_index = page * opts[:per_page]
        end_index = start_index + opts[:per_page] - 1

        results[start_index..end_index].each_with_index do |result, index|
          row = []
          if opts[:with_numbers]
            row << "  #{start_index + index + 1}:  "
          end
          opts[:columns].each do |c|
            if c.is_a?(Symbol)
              key = c
            elsif c.is_a?(Array)
              key = c.first
            elsif c.is_a?(Hash)
              key = c[:key]
            else
              say("Invalid pagination call...")
              return
            end
            row << (result[key] || result[key.to_s])
          end
          table << row
        end
        print_table(table)

        if results.size <= end_index
          break
        else
          page += 1
          say
          ask("Press enter to view more results...")
        end
      end

      say(opts[:footer]) if opts[:footer]
      say
    end

end
