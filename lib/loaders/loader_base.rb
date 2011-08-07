# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
#  Details::  Base class for loaders, providing a process hook which populates a model,
#             based on a method map and supplied value from a file - i.e a single column/row's string value.
#             Note that although a single column, the string can be formatted to contain multiple values.
#
#             Tightly coupled with MethodMapper classes (in lib/engine) which contains full details of
#             a file's column and it's correlated AR associations.
#
class LoaderBase

  attr_accessor :load_object_class, :load_object, :value

  # Enable single column (association) to contain multiple name/value sets in default form :
  #   Name1:value1, value2|Name2:value1, value2, value3|Name3:value1, value2
  #
  # E.G.
  #   Row for association could have a name (Size/Colour/Sex) with a set of values,
  #   and this combination can be expressed multiple times :
  #   Size:small,medium,large|Colour:red, green|Sex:Female

  @@name_value_delim  = ':'
  @@multi_value_delim = ','
  @@multi_assoc_delim = '|'

  def self.set_name_value_delim(x)  @@name_value_delim = x; end
  def self.set_multi_value_delim(x) @@multi_value_delim = x; end
  def self.set_multi_assoc_delim(x) @@multi_assoc_delim = x; end

  def initialize(object_class, object = nil)
    @load_object_class = object_class
    @load_object = object || @load_object_class.new
  end

  def reset()
    @load_object = @load_object_class.new
  end
  
  # What process a value string from a column.
  # Assigning value(s) to correct association on @load_object.
  # Method map represents a column from a file and it's correlated AR associations.
  # Value string which may contain multiple values for a collection association.
  # 
  def process(method_map, value)
    #puts "INFO: LOADER BASE processing #{@load_object}"
    @value = value
    
    if(method_map.has_many && method_map.has_many_class && @value)
      # The Generic handler for Associations
      # The actual class of the association so we can find_or_create on it
      assoc_class = method_map.has_many_class

      puts "Processing Association: #{assoc_class} : #{@value}"

      @value.split(@@multi_assoc_delim).collect do |lookup|
        # TODO - Don't just rely on 'name' but try different finds as per MethodMappe::insistent_belongs_to ..
        x = assoc_class.find(:first, :conditions => ['lower(name) LIKE ?', "%#{lookup.downcase}%"])
        unless x
          puts "WARNING: #{lookup} in #{assoc_class} NOT found - Not added to #{@load_object.class}"
          next
        end
        @load_object.send( method_map.has_many ) << x
        @load_object.save
      end
    else
      # Nice n simple straight assignment to a column variable
      method_map.assign(@load_object, @value) unless method_map.has_many
    end
  end

end