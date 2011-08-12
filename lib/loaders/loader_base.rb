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

  attr_accessor :load_object_class, :load_object
  attr_accessor :current_value

  attr_accessor :loaded_objects

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
    @load_object = object || new_load_object
    @loaded_count = 0
  end

  def new_load_object
    @load_object = @load_object_class.new
  end

  def reset()
    new_load_object
    @loaded_objects.clear
  end

  def loaded_count
    @loaded_objects.size
  end
  # Search method mapper for supplied klass and column,
  # and if suitable association found, process row data into current load_object
  def find_and_process(klass, column_name, row_data)
    method_detail = MethodMapper.find_method_detail( klass, column_name )

    process(method_detail, row_data) if method_detail
  end


  # What process a value string from a column.
  # Assigning value(s) to correct association on @load_object.
  # Method detail represents a column from a file and it's correlated AR associations.
  # Value string which may contain multiple values for a collection association.
  # 
  def process(method_detail, value)
    #puts "INFO: LOADER BASE processing #{@load_object}"
    @current_value = value
    
    if(method_detail.has_many)

      if(method_detail.has_many_class && @current_value)

        puts "Processing Association: #{method_detail} : #{@current_value}"

        @current_value.split(@@multi_assoc_delim).collect do |lookup|
          method_detail.assign(@load_object, @current_value)
        end

        begin
          @load_object.save if( load_object.valid? )
        rescue
          raise "Error processing #{method_detail.name}"
        end
      end
    else
      # Nice n simple straight assignment to a column variable
      method_detail.assign(@load_object, @current_value)
    end
  end

end