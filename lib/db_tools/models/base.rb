class DbTools::Models::Base
  attr_reader :attributes

  def initialize(attrs = {})
    @attributes = {}
    attrs.each do |key, value|
      # pp [self.class.name, key, self.class.attributes, self.class.attributes.include?(key.to_sym)]
      next unless self.class.attributes.include?(key.to_sym)
      @attributes[key.to_sym] = value
    end
  end

  def self.attributes(*attrs)
    @attribute_names ||= []
    @attribute_names += attrs.collect{|a| a.to_sym} unless attrs.nil?
    @attribute_names
  end
  def self.belongs_to(*attrs) self.attributes(*attrs); end
  def self.has_many(*attrs) self.attributes(*attrs); end

  def method_missing(meth, *args, &block)
    method_name = meth.to_s
    method_suffix = method_name[-1, 1]
    method_key = method_name.to_sym
    if ['=', '?'].include?(method_suffix)
      method_key = method_name[0..-2].to_sym 
    end

    if self.class.attributes.index(method_key)
      if method_name[-1, 1] == '='
        attributes[method_key] = args.first
        return attributes[method_key]
      end
      return attributes[method_key]
    end

    super
  end      

  def to_hash(*attrs)
    if attrs.nil? or attrs.empty?
      # default hashing only includes basic types
      keys = []
      self.class.attributes.each do |key|
        value = attributes[key]
        next if value.is_a?(DbTools::Models::Base) or value.kind_of?(Hash) or value.kind_of?(Array)
        keys << key
      end
    else
      keys = attrs
    end

    hash = {}
    keys.each do |key|
      hash[key] = attributes[key]
    end

    # proc = Proc.new { |k, v| v.kind_of?(Hash) ? (v.delete_if(&l); nil) : v.nil? }
    # hash.delete_if(&proc)

    hash    
  end

end