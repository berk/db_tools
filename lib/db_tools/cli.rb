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

class DbTools::Cli < DbTools::Base

    class << self
      def source_root
        File.expand_path('../../',__FILE__)
      end
    end

    desc 'server', 'Starts a web server that you can connect to from a browser'
    def server
      DbTools::Server::App.run!
    end

    desc 'default', "Shows default connection and allows to select a different default connection"
    method_option :connection, :type => :string, :aliases => "-c", :required => false, :banner => "Connection name", :default => nil
    def default
      if options[:connection]
        if config["connections"][options[:connection]]
          selected_connection = options[:connection]
        else
          say("Invalid connection name.")
        end
      end

      unless selected_connection
        say
        say("Current default connection: #{defaults['connection']}")

        cons = []
        config["connections"].each do |key, con|
          cons << con.merge('key' => key)
        end
        paginate(cons, :header => "Select new default connections:", :columns => [:key, :adapter, :host, :database], :with_numbers => true)

        say("Select new default connection:")
        num = ask_for_number(cons.size, opts = {})
        selected_connection = cons[num-1]['key']
      end

      config['default']['connection'] = selected_connection
      update_config
      say("Default connection has been updated")
    end

    desc 'connect', "Creates and stores a new connection configuration"
    def connect
      hash = {}
      name = ask("connection name:")
      hash['adapter'] = ask("Adapter:")
      hash['host'] = ask("Host:")
      hash['username'] = ask("Username:")
      hash['password'] = ask("Password:")
      hash['database'] = ask("Database:")
      hash.delete_if{|key, value| value == ""}

      ActiveRecord::Base.establish_connection(hash)

      config['connections'].delete('temp')

      config['connections'][name] = hash
      config['default']['connection'] = name

      update_config

      say("Connection has been created succesfully")
    end

    map 'c' => :connections
    desc 'connections', "Lists all available connections"
    def connections
      cons = []
      config["connections"].each do |key, con|
        cons << con.merge('key' => key)
      end
      paginate(cons, :header => "Saved connections:", :columns => [:key, :adapter, :host, :database], :with_numbers => true)
      say
      say("Default connection: #{defaults['connection']}")
      say
    end

    map 't' => :tables
    desc 'tables', "Lists all tables from a connection"
    method_option :connection, :type => :string, :aliases => "-c", :required => false, :banner => "Connection name", :default => nil
    method_option :filter, :type => :string, :aliases => "-f", :required => false, :banner => "Only include tables that match filter value", :default => nil
    def tables
      conn = connection(options[:connection])
      ActiveRecord::Base.establish_connection(conn.to_hash)

      database = DbTools::Models::Database.init(conn, ActiveRecord::Base.connection.tables, options)
      tables = database.tables(options).collect do |table|
        {:name => table.name, :columns => table.columns.size}
      end

      header = "Tables in #{conn.name}"
      header << " that match \"#{options['filter']}\"" if options['filter']

      paginate(tables, :header => header, :with_numbers => true)
    end

    map 'd' => :describe
    desc 'describe', "Displays table structure"
    method_option :connection, :type => :string, :aliases => "-c", :required => false, :banner => "Connection name", :default => nil
    def describe(table_name)
      conn = connection(options[:connection])
      ActiveRecord::Base.establish_connection(conn.to_hash)
      
      table = DbTools::Models::Table.init(Class.new(ActiveRecord::Base){self.table_name = table_name})

      paginate(table.columns.collect{|c| c.to_hash}, :header => "#{table.name} in #{conn.name}", :with_numbers => true)
    end

    map 'q' => :query
    desc 'query', 'Queries a connection and displayes results'
    method_option :connection, :type => :string, :aliases => "-c", :required => false, :banner => "Connection name", :default => nil
    method_option :json, :type => :string, :aliases => "-j", :required => false, :banner => "Connection name", :default => nil
    def query(sql)
      conn = connection(options[:connection])
      ActiveRecord::Base.establish_connection(conn.to_hash)

      results = ActiveRecord::Base.connection.execute(sql)

      if options['json']
        say(results.to_json)
        return
      end

      paginate(results, :header => "#{conn.name}: #{sql}")
    end

    desc 'compare', 'Compares a table between two connections'
    method_option :source, :type => :string, :aliases => "-s", :required => true, :banner => "Source connection", :default => nil
    method_option :target, :type => :string, :aliases => "-t", :required => true, :banner => "Target connection", :default => nil
    def compare(table_name)
      source_conn = connection(options[:source])
      ActiveRecord::Base.establish_connection(source_conn.to_hash)
      source_table = DbTools::Models::Table.init(Class.new(ActiveRecord::Base){self.table_name = table_name})
      paginate(source_table.columns.collect{|c| c.to_hash}, :header => "#{source_table.name} in #{options[:source]}", :with_numbers => true)

      target_conn = connection(options[:target])
      ActiveRecord::Base.establish_connection(target_conn.to_hash)
      target_table = DbTools::Models::Table.init(Class.new(ActiveRecord::Base){self.table_name = table_name})
      paginate(target_table.columns.collect{|c| c.to_hash}, :header => "#{target_table.name} in #{options[:target]}", :with_numbers => true)

      results = source_table.compare(target_table)
      say("Summary of changes:")
      say

      say("Changed columns: #{results[:changed].join(', ')}") if results[:changed].any?
      say("Added columns: #{results[:added].join(', ')}") if results[:added].any?
      say("Removed columns: #{results[:deleted].join(', ')}") if results[:deleted].any?
      say

      say("ActiveRecord migration:")
      say

      migration = DbTools::Models::Migration.init(source_table, target_table)
      say(migration.generate)
      say
    end

    desc 'migrate', 'Generates migrations between two database'
    method_option :source, :type => :string, :aliases => "-s", :required => true,   :banner => "Source connection", :default => nil
    method_option :target, :type => :string, :aliases => "-t", :required => true,   :banner => "Target connection", :default => nil
    method_option :filter, :type => :string, :aliases => "-f", :required => false,  :banner => "Target connection", :default => nil
    def migrate
      source_conn = connection(options[:source])
      ActiveRecord::Base.establish_connection(source_conn.to_hash)
      source_database = DbTools::Models::Database.init(source_conn, ActiveRecord::Base.connection.tables, options)

      target_conn = connection(options[:target])
      ActiveRecord::Base.establish_connection(target_conn.to_hash)
      target_database = DbTools::Models::Database.init(target_conn, ActiveRecord::Base.connection.tables, options)

      results = source_database.compare(target_database, options)

      say("Summary of changes:")
      say

      say("Changed tables: #{results[:changed].join(', ')}") if results[:changed].any?
      say("\nAdded tables: #{results[:added].join(', ')}") if results[:added].any?
      say("\nRemoved tables: #{results[:deleted].join(', ')}") if results[:deleted].any?
      say

    end


end
