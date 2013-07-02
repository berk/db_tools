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

class DbTools::Models::Connection < DbTools::Models::Base
  
  attributes :name, :adapter, :host, :username, :password, :database

  def establish
    ActiveRecord::Base.establish_connection(self.to_hash)    
    self
  end

  def tables
    ActiveRecord::Base.connection.tables
  end

  def execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end

  def columns(table_name)
    ActiveRecord::Base.connection.columns(table_name)
  end

  def indexes(table_name)
    ActiveRecord::Base.connection.indexes(table_name)
  end

  def to_ext_hash
    {
      'id'    => "connection:#{name}",
      'key'   => "connection",
      'label' => adapter,
      'text'  => name,
      'cls'   => 'folder',
    }
  end

end