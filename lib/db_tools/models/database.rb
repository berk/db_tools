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

require 'erb'

class DbTools::Models::Database < DbTools::Models::Base
  belongs_to :connection
  has_many :tables

  def self.init(connection, options = {})
    database = new({
      :connection => connection
    })

    database.tables = []
    connection.tables.sort.each do |table_name|
      table = DbTools::Models::Table.init(connection, table_name, options)
      table.database = database
      database.tables << table
    end

    database
  end

  def name
    connection.database
  end

  def tables(options = {})
    return super unless options["filter"]
    tbls = []
    self.attributes[:tables].each do |table|
      next if options["filter"] and not table.name.index(options["filter"])
      tbls << table
    end
    tbls
  end

  def table(name)
    @tables_by_name ||= begin
      tbls = {}  
      tables.each do |table|
        tbls[table.name] = table
      end
      tbls
    end
    @tables_by_name[name]
  end

  def compare(database, options = {})
    added_tables = []
    deleted_tables = []
    changed_tables = []

    target_tables = {}
    database.tables(options).each do |tbl|
      target_tables[tbl.name] = tbl
    end

    tables(options).each do |table|
      if target_tables[table.name]
        unless table.similar?(target_tables[table.name])
          changed_tables << table.name
        end        
      else
        deleted_tables << table.name
      end

      target_tables.delete(table.name)
    end    
    added_tables = target_tables.keys

    {:changed => changed_tables, :added => added_tables, :deleted => deleted_tables}
  end

  def similar?(database)
    results = compare(database)
    0 == results[:changed].size + results[:added].size + results[:deleted].size
  end

  def migrate(database)
    changes = compare(database)

  end

end