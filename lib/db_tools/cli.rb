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

    map 's' => :server
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
        say("Current default connection: #{DbTools::Config.defaults['connection']}")

        cons = DbTools::Config.connections.collect{|con| con.to_hash}
        paginate(cons, :header => "Select new default connection:", :columns => [:name, :adapter, :host, :database], :with_numbers => true)

        num = ask_for_number(cons.size, opts = {})
        selected_connection = cons[num-1][:name]
      end

      DbTools::Config.config['default']['connection'] = selected_connection
      DbTools::Config.update_config
      say("Default connection has been set to: #{selected_connection}")
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

      DbTools::Config.config['connections'].delete('temp')

      DbTools::Config.config['connections'][name] = hash
      DbTools::Config.config['default']['connection'] = name

      DbTools::Config.update_config

      say("Connection has been created succesfully")
    end

    map 'c' => :connections
    desc 'connections', "Lists all available connections"
    def connections
      cons = DbTools::Config.connections.collect{|con| con.to_hash}
      paginate(cons, :header => "Saved connections:", :columns => [:name, :adapter, :host, :database], :key => :name)
      say
      say("Default connection: #{DbTools::Config.defaults['connection']}")
      say
    end

    map 't' => :tables
    desc 'tables', "Lists all tables from a connection"
    method_option :connection, :type => :string, :aliases => "-c", :required => false, :banner => "Connection name", :default => nil
    method_option :filter, :type => :string, :aliases => "-f", :required => false, :banner => "Only include tables that match filter value", :default => nil
    def tables
      conn = DbTools::Config.connection(options[:connection])
      database = DbTools::Models::Database.init(conn, options)
      tables = database.tables(options).collect do |table|
        {:name => table.name, :columns => table.columns.size, :indexes => table.indexes.size}
      end

      header = "Tables in #{conn.name}"
      header << " that match \"#{options['filter']}\"" if options['filter']

      paginate(tables, :header => header, :with_numbers => true)
    end

    map 'd' => :describe
    desc 'describe', "Displays table structure"
    method_option :connection, :type => :string, :aliases => "-c", :required => false, :banner => "Connection name", :default => nil
    def describe(table_name)
      conn = DbTools::Config.connection(options[:connection]).establish      
      table = DbTools::Models::Table.init(conn, table_name)

      paginate(table.columns.collect{|c| c.to_hash}, :header => "#{table.name} in #{conn.name}", :with_numbers => true)
      paginate(table.indexes.collect{|i| i.to_hash}, :header => "Indexes:", :with_numbers => true)
    end

    map 'q' => :query
    desc 'query', 'Queries a connection and displayes results'
    method_option :connection, :type => :string, :aliases => "-c", :required => false, :banner => "Connection name", :default => nil
    method_option :json, :type => :string, :aliases => "-j", :required => false, :banner => "Connection name", :default => nil
    def query(sql)
      conn = DbTools::Config.connection(options[:connection])
      results = conn.execute(sql)

      if options['json']
        say(results.to_json)
        return
      end

      paginate(results.to_a, :header => "#{conn.name}: #{sql}")
    end

    desc 'compare', 'Compares a table between two connections'
    method_option :source, :type => :string, :aliases => "-s", :required => true, :banner => "Source connection", :default => nil
    method_option :target, :type => :string, :aliases => "-t", :required => true, :banner => "Target connection", :default => nil
    def compare(table_name)
      source_conn = DbTools::Config.connection(options[:source]).establish
      source_table = DbTools::Models::Table.init(source_conn, table_name)
      paginate(source_table.columns.collect{|c| c.to_hash}, :header => "#{source_table.name} in #{options[:source]}:", :with_numbers => true)
      paginate(source_table.indexes.collect{|i| i.to_hash}, :header => "Indexes:", :with_numbers => true)

      target_conn = DbTools::Config.connection(options[:target]).establish
      target_table = DbTools::Models::Table.init(target_conn, table_name)
      paginate(target_table.columns.collect{|c| c.to_hash}, :header => "#{target_table.name} in #{options[:target]}:", :with_numbers => true)
      paginate(target_table.indexes.collect{|i| i.to_hash}, :header => "Indexes:", :with_numbers => true)

      results = source_table.compare(target_table)
      say("Summary of changes:")
      say

      say("Changed columns: #{results[:columns][:changed].join(', ')}") if results[:columns][:changed].any?
      say("Added columns: #{results[:columns][:added].join(', ')}") if results[:columns][:added].any?
      say("Removed columns: #{results[:columns][:deleted].join(', ')}") if results[:columns][:deleted].any?
      say

      say("ActiveRecord migration:")
      say

      migration = DbTools::Models::Migrations::Table.init(source_table, target_table)
      say(migration.generate)
      say
    end

    desc 'migrate', 'Generates migrations between two database'
    method_option :source, :type => :string, :aliases => "-s", :required => true,   :banner => "Source connection", :default => nil
    method_option :target, :type => :string, :aliases => "-t", :required => true,   :banner => "Target connection", :default => nil
    method_option :filter, :type => :string, :aliases => "-f", :required => false,  :banner => "Target connection", :default => nil
    def migrate
      source_conn = DbTools::Config.connection(options[:source]).establish
      source_database = DbTools::Models::Database.init(source_conn, source_conn.tables, options)

      target_conn = DbTools::Config.connection(options[:target]).establish
      target_database = DbTools::Models::Database.init(target_conn, target_conn.tables, options)

      results = source_database.compare(target_database, options)

      say("Summary of changes:")
      say

      say("Changed tables: #{results[:changed].join(', ')}") if results[:changed].any?
      say("\nAdded tables: #{results[:added].join(', ')}") if results[:added].any?
      say("\nRemoved tables: #{results[:deleted].join(', ')}") if results[:deleted].any?
      say

      migration = DbTools::Models::Migrations::Database.init(source_database, target_database)
      say(migration.generate)
      say
    end

end
