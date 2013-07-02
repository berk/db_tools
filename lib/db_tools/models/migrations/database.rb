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

class DbTools::Models::Migrations::Database < DbTools::Models::Migrations::Base
  
  attributes :name, :options, :source_database, :target_database, :changed_tables, :added_tables, :deleted_tables

  def self.init(source_database, target_database, options = {})
    new(
      :name => options[:name] || "Update#{source_database.name.camelcase}",
      :source_database => source_database,
      :target_database => target_database,
      :options => options
    )
  end

  def table_name
    target_table.name
  end

  def template_file_name
    "active_record_database.erb"
  end

  def prepare
    results = source_database.compare(target_database, options)
    self.changed_tables = results[:changed]
    self.added_tables = results[:added]    
    self.deleted_tables = results[:deleted]    

    @changes_up = []
    @changes_down = []
    changed_tables.each do |key| 
      mig = DbTools::Models::Migrations::Table.init(source_database.table(key), target_database.table(key)).prepare
      @changes_up << mig.column_changes_up
      @changes_up << ""
      @changes_up << mig.index_changes_up
      @changes_up << ""
      @changes_down << mig.column_changes_down
      @changes_down << ""
      @changes_down << mig.index_changes_down
      @changes_down << ""
    end

    @changes_up.flatten!
    @changes_down.flatten!

    self
  end

  def changes_up
    @changes_up
  end

  def changes_down
    @changes_down
  end

  def additions_up
    added_tables.collect do |key| 
      target_database.table(key).statement(:create) + "\n"
    end
  end

  def additions_down
    added_tables.collect do |key| 
      target_database.table(key).statement(:drop) 
    end
  end

  def deletions_up
    deleted_tables.collect do |key| 
      source_database.table(key).statement(:drop) 
    end
  end

  def deletions_down
    deleted_tables.collect do |key| 
      source_database.table(key).statement(:create) + "\n"
    end
  end  

end