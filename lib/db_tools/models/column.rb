class DbTools::Models::Column < DbTools::Models::Base
  belongs_to :table
  attributes :name, :type, :sql_type, :limit, :default, :scale, :precision, :primary, :null, :coder

  def similar?(column)
    [:name, :type, :limit, :scale, :precision, :primary, :null].each do |key|
      return false unless column.attributes[key] == attributes[key]
    end
    true
  end

end