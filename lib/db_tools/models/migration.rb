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

class DbTools::Models::Migration < DbTools::Models::Base
  
  attributes :name, :source_table, :target_table, :changed_columns, :added_columns, :deleted_columns

  def self.init(source_table, target_table, opts = {})
    new(
      :name => opts[:name] || "Update#{source_table.name.camelcase}",
      :source_table => source_table,
      :target_table => target_table,
    )
  end

  def table_name
    target_table.name
  end

  def generate
    results = source_table.compare(target_table)
    self.changed_columns = results[:changed]
    self.added_columns = results[:added]    
    self.deleted_columns = results[:deleted]    
    @migration = self

    template = File.expand_path(File.join(File.dirname(__FILE__), "../../templates/migrations/active_record.erb"))
    ERB.new(File.read(template)).result(binding)
  end

  def changes_up
    changed_columns.collect do |key| 
      column = target_table.column(key) 
      "change_column :#{table_name}, :#{column.name}, :#{column.type}, :null => #{column.null}"
    end
  end

  def additions_up
    added_columns.collect do |key| 
      column = target_table.column(key) 
      "add_column :#{table_name}, :#{column.name}, :#{column.type}, :null => #{column.null}"
    end
  end

  def deletions_up
    deleted_columns.collect do |key| 
      column = source_table.column(key) 
      "delete_column :#{table_name}, :#{column.name}"
    end
  end

  def changes_down
    changed_columns.collect do |key| 
      column = source_table.column(key) 
      "change_column :#{table_name}, :#{column.name}, :#{column.type}, :null => #{column.null}"
    end
  end

  def additions_down
    added_columns.collect do |key| 
      column = target_table.column(key) 
      "delete_column :#{table_name}, :#{column.name}"
    end
  end

  def deletions_down
    deleted_columns.collect do |key| 
      column = source_table.column(key) 
      "add_column :#{table_name}, :#{column.name}, :#{column.type}, :null => #{column.null}"
    end
  end
end