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

class DbTools::Models::Table < DbTools::Models::Base
  
  belongs_to :database
  has_many :columns  
  attributes :name

  def self.init(cls, opts = {})
    table = DbTools::Models::Table.new(
      :name => cls.table_name
    )
    table.columns = cls.columns.collect{ |c| 
      DbTools::Models::Column.new(
        :table => table, :name => c.name,
        :type => c.type, :sql_type => c.sql_type, 
        :limit => c.limit, :default => c.default, :scale => c.scale, :precision => c.precision, 
        :primary => c.primary, :null => c.null, :coder => c.coder
      )
    }
    table
  end 

  def column(name)
    @columns_by_name ||= begin
      cbn = {}  
      columns.each do |column|
        cbn[column.name] = column
      end
      cbn
    end
    @columns_by_name[name]
  end

  def compare(table)
    added_columns = []
    deleted_columns = []
    changed_columns = []

    target_columns = {}
    table.columns.each do |col|
      target_columns[col.name] = col
    end

    columns.each do |column|
      if target_columns[column.name]
        unless column.similar?(target_columns[column.name])
          changed_columns << column.name
        end        
      else
        deleted_columns << column.name
      end

      target_columns.delete(column.name)
    end
    
    added_columns = target_columns.keys

    {:changed => changed_columns, :added => added_columns, :deleted => deleted_columns}
  end

  def similar?(table)
    results = compare(table)
    0 == results[:changed].size + results[:added].size + results[:deleted].size
  end
  
end