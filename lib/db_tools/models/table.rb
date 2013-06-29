class DbTools::Models::Table < DbTools::Models::Base
  
  belongs_to :connection
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

end