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

class DbTools::Models::Migrations::Table < DbTools::Models::Migrations::Base
  
  attributes :name, :source_table, :target_table
  attributes :results

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

  def template_file_name
    "active_record_table.erb"
  end

  def prepare
    self.results = source_table.compare(target_table)
    self
  end

  def column_changes_up
    results[:columns][:changed].collect do |key| 
      target_table.column(key).statement(:change) 
    end
  end

  def column_changes_down
    results[:columns][:changed].collect do |key| 
      source_table.column(key).statement(:change) 
    end
  end

  def column_additions_up
    results[:columns][:added].collect do |key| 
      target_table.column(key).statement(:add) 
    end
  end

  def column_additions_down
    results[:columns][:added].collect do |key| 
      target_table.column(key).statement(:remove) 
    end
  end

  def column_deletions_up
    results[:columns][:deleted].collect do |key| 
      source_table.column(key).statement(:remove) 
    end
  end

  def column_deletions_down
    results[:columns][:deleted].collect do |key| 
      source_table.column(key).statement(:add) 
    end
  end  


  def index_additions_up
    results[:indexes][:added].collect do |key| 
      target_table.index(key).statement(:add) 
    end
  end

  def index_additions_down
    results[:indexes][:added].collect do |key| 
      target_table.index(key).statement(:remove) 
    end
  end

  def index_deletions_up
    results[:indexes][:deleted].collect do |key| 
      source_table.index(key).statement(:remove) 
    end
  end

  def index_deletions_down
    results[:indexes][:deleted].collect do |key| 
      source_table.index(key).statement(:add) 
    end
  end

  def index_changes_up
    results[:indexes][:changed].collect do |key| 
      [source_table.index(key).statement(:remove), target_table.index(key).statement(:add)]
    end.flatten
  end

  def index_changes_down
    results[:indexes][:changed].collect do |key| 
      [target_table.index(key).statement(:remove), source_table.index(key).statement(:add)]
    end.flatten
  end

end