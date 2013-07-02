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
  
  belongs_to :connection
  belongs_to :database
  has_many :columns, :indexes  
  attributes :name

  def self.init(connection, table_name, opts = {})
    table = DbTools::Models::Table.new(
      :connection => connection,
      :name => table_name
    )

    #<ActiveRecord::ConnectionAdapters::SQLite3Column:0x007fd4ec44b240 @name=\"definition\", @sql_type=\"text\", @null=true, @limit=nil, @precision=nil, @scale=nil, @type=:text, @default=nil, @primary=nil, @coder=nil

    table.columns = []
    table.indexes = []

    unless opts[:no_columns]
      table.columns = connection.columns(table_name).collect{ |c| 
        DbTools::Models::Column.new(
          :table => table, :name => c.name,
          :type => c.type, :sql_type => c.sql_type, 
          :limit => c.limit, :default => c.default, :scale => c.scale, :precision => c.precision, 
          :primary => c.primary, :null => c.null, :coder => c.coder
        )
      }
    end

    "#<struct ActiveRecord::ConnectionAdapters::IndexDefinition table=\"tr8n_applications\", name=\"tr8n_apps\", unique=false, columns=[\"key\"], lengths=nil, orders=nil, where=nil, type=nil, using=nil>"

    unless opts[:no_indexes]
      table.indexes = connection.indexes(table_name).collect{ |i| 
        DbTools::Models::Index.new(
          :table => table, :name => i.name,
          :unique => i.unique, :columns => i.columns,
          :lengths => i.lengths, :orders => i.orders,
          :where => i.where, :type => i.type, :using => i.using
        )
      }
    end

    table
  end 

  def model
    Class.new(ActiveRecord::Base){self.table_name = name}
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

  def compare_columns(table)
    added = []
    deleted = []
    changed = []

    target_columns = {}
    table.columns.each do |col|
      target_columns[col.name] = col
    end

    columns.each do |column|
      if target_columns[column.name]
        unless column.similar?(target_columns[column.name])
          changed << column.name
        end        
      else
        deleted << column.name
      end

      target_columns.delete(column.name)
    end
    
    added = target_columns.keys

    {:changed => changed, :added => added, :deleted => deleted}
  end

  def index(name)
    @indexes_by_name ||= begin
      indxs = {}  
      indexes.each do |i|
        indxs[i.name] = i
      end
      indxs
    end
    @indexes_by_name[name]
  end

  def compare_indexes(table)
    added = []
    deleted = []
    changed = []

    target_indexes = {}
    table.indexes.each do |i|
      target_indexes[i.name] = i
    end

    indexes.each do |i|
      if target_indexes[i.name]
        unless i.similar?(target_indexes[i.name])
          changed << i.name
        end        
      else
        deleted << i.name
      end

      target_indexes.delete(i.name)
    end
    
    added = target_indexes.keys

    {:changed => changed, :added => added, :deleted => deleted}
  end

  def compare(table)
    {
      :columns => compare_columns(table),
      :indexes => compare_indexes(table)
    }
  end

  def similar?(table)
    results = compare(table)
    total = 0
    [:columns, :indexes].each do |type|
      [:changed, :added, :deleted].each do |result|
        total += results[type][result].size
      end
    end
    total == 0
  end

  def max_type_length
    @max_type_length ||= columns.max {|a,b| a.type.length <=> b.type.length}.type.length  
  end

  def name_spacer(type)
    " " * ((max_type_length + 5) - type.length) 
  end

  def statement(type, opts = {})
    opts[:spacer] ||= "    "
    case type
    when :create 
      lines = []
      lines << "create_table :#{name} do |t|"
      columns.each do |col|
        lines << "#{opts[:spacer]}  t.#{col.type}#{name_spacer(col.type)}:#{col.name}, #{col.options(:skip_default => true).join(', ')}"
      end
      lines << "#{opts[:spacer]}end"
      indexes.each do |ind|
        lines << "#{opts[:spacer]}#{ind.statement(:add)}"
      end
      return lines.join("\n")
    when :drop 
      return "drop table :#{name}"
    when :rename 
      return "rename_table :#{name}, :#{opts[:name]}"
    end

    raise "Unknown statement type"
  end

  def to_ext_hash
    {
      'id'    => name,
      'key'   => name,
      'label' => name,
      'text'  => name,
      'cls'   => 'folder',
    }
  end

end