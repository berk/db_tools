#--
# Copyright (c) 2012 Michael Berkovich
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
      connection_name = options[:connection] || defaults['connection']
      ActiveRecord::Base.establish_connection(config['connections'][connection_name])

      tables = []
      ActiveRecord::Base.connection.tables.sort.each do |table_name|
        next if options[:filter] and not table_name.index(options[:filter])

        table = DbTools::Models::Table.init(Class.new(ActiveRecord::Base){self.table_name = table_name})

        info = {:name => table_name}
        info[:columns] = table.columns.size
        # info[:rows] = cls.count
        tables << info
      end

      header = "Tables in #{connection_name}"
      header << " that match \"#{options['filter']}\"" if options['filter']

      paginate(tables, :header => header, :with_numbers => true)
    end

    map 'd' => :describe
    desc 'describe', "Displays table structure"
    method_option :connection, :type => :string, :aliases => "-c", :required => false, :banner => "Connection name", :default => nil
    def describe(table_name)
      connection_name = options[:connection] || defaults['connection']
      ActiveRecord::Base.establish_connection(config['connections'][connection_name])
      table = DbTools::Models::Table.init(Class.new(ActiveRecord::Base){self.table_name = table_name})

      paginate(table.columns.collect{|c| c.to_hash}, :header => "#{table_name} in #{connection_name}", :with_numbers => true)
    end

    map 'q' => :query
    desc 'query', 'Queries a connection and displayes results'
    method_option :connection, :type => :string, :aliases => "-c", :required => false, :banner => "Connection name", :default => nil
    method_option :json, :type => :string, :aliases => "-j", :required => false, :banner => "Connection name", :default => nil
    def query(sql)
      connection_name = options[:connection] || defaults['connection']
      ActiveRecord::Base.establish_connection(config['connections'][connection_name])
      results = ActiveRecord::Base.connection.execute(sql)

      if options['json']
        say(results.to_json)
        return
      end

      paginate(results, :header => "#{connection_name}: #{sql}")
    end


    desc 'compare', 'Compares a table between two connections'
    method_option :source, :type => :string, :aliases => "-s", :required => true, :banner => "Source connection", :default => nil
    method_option :target, :type => :string, :aliases => "-t", :required => true, :banner => "Target connection", :default => nil
    def compare(table_name)
      ActiveRecord::Base.establish_connection(config['connections'][options[:source]])
      source_table = DbTools::Models::Table.init(Class.new(ActiveRecord::Base){self.table_name = table_name})
      paginate(source_table.columns.collect{|c| c.to_hash}, :header => "#{source_table.name} in #{options[:source]}", :with_numbers => true)

      ActiveRecord::Base.establish_connection(config['connections'][options[:target]])
      target_table = DbTools::Models::Table.init(Class.new(ActiveRecord::Base){self.table_name = table_name})
      paginate(target_table.columns.collect{|c| c.to_hash}, :header => "#{target_table.name} in #{options[:target]}", :with_numbers => true)

      results = source_table.compare(target_table)
      # pp :source, source_table.columns.collect{|c| c.name}
      # pp :target, target_table.columns.collect{|c| c.name}
      pp results
    end

    desc 'migrate', 'Compares a table between databases'
    def migrate(source, target)
      ActiveRecord::Base.establish_connection(config['connections'][source])
      source_table = DbTools::Models::Table.init(Class.new(ActiveRecord::Base){self.table_name = table_name})

      ActiveRecord::Base.establish_connection(config['connections'][target])
      target_table = DbTools::Models::Table.init(Class.new(ActiveRecord::Base){self.table_name = table_name})

      pp :source, source_table.columns.collect{|c| c.name}

      pp :target, target_table.columns.collect{|c| c.name}

      # columns = table.columns.collect{|c| c.to_hash}

      # # cls.columns.each do |c|
      # #   columns << {:name => c.name, :type => c.type, :sql_type => c.sql_type, :limit => c.limit, :default => c.default, :scale => c.scale, :precision => c.precision, :primary => c.primary, :null => c.null, :coder => c.coder}
      # # end

      # paginate(columns, :header => "#{table_name}", :with_numbers => true)
    end


end
