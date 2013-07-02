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

class DbTools::Models::Index < DbTools::Models::Base
  belongs_to :table
  attributes :name, :unique, :columns, :lengths, :orders, :where, :type, :using

  def similar?(index)
    [:name, :unique, :columns, :lengths, :orders, :where, :type, :using].each do |key|
      return false unless index.attributes[key] == attributes[key]
    end
    true
  end

  def options(opts = {})
    sections = []
    # sections << ":limit => #{self.limit}" if self.limit
    # sections << ":scale => #{self.scale}" if self.scale
    # sections << ":precision => #{self.precision}" if self.precision
    # sections << ":default => #{self.default}" if self.default
    # sections << ":null => #{self.null}"
    sections
  end

  def statement(type, opts = {})
    case type
    when :add 
      return "add_index :#{table.name}, :#{self.name}, :#{self.type}, #{options.join(', ')}"
    when :remove 
      return "remove_index :#{table.name}, :#{self.name}"
    end

    raise "Unknown statement type"
  end

  def to_hash(*attrs)
    if attrs.nil? or attrs.empty?
      # default hashing only includes basic types
      keys = []
      self.class.attributes.each do |key|
        value = attributes[key]
        next if value.is_a?(DbTools::Models::Base)
        keys << key
      end
    else
      keys = attrs
    end

    hash = {}
    keys.each do |key|
      hash[key] = attributes[key]
    end

    hash    
  end

end
