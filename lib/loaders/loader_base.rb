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
  attr_accessor :current_value, :current_method_detail

  attr_accessor :loaded_objects, :failed_objects

  attr_accessor :options

  # Enable an entry representing an association to contain multiple lookup name/value sets in default form :
  #   Name1:value1, value2|Name2:value1, value2, value3|Name3:value1, value2
  #
  # E.G.
  #   Row for association could have a columns called Size and once called Colour,
  #   and this combination could be used to lookup multiple associations to add to the main model
  #
  #     Size:small => generates find_by_size( 'small' )
  #
  #       Size:large|Colour:red,green,blue   => generates find_by_size( 'large' ) and find_all_by_colour( ['red','green','blue'] )
  #
  @@name_value_delim  = ':'
  @@multi_value_delim = ','
  @@multi_assoc_delim = '|'

  def self.set_name_value_delim(x)  @@name_value_delim = x; end
  def self.set_multi_value_delim(x) @@multi_value_delim = x; end
  def self.set_multi_assoc_delim(x) @@multi_assoc_delim = x; end

  # Options
  def initialize(object_class, object = nil, options = {})
    @load_object_class = object_class
    @options = options.clone
    reset(object)
  end

  def reset(object = nil)
    @load_object = object || new_load_object
    @loaded_objects, @failed_objects = [],[]
    @current_value = nil
  end

  def new_load_object
    @load_object = @load_object_class.new
    @load_object
  end

  def abort_on_failure?
    @options[:abort_on_failure] == 'true'
  end

  def loaded_count
    @loaded_objects.size
  end

  def failed_count
    @failed_objects.size
  end
  
  # Search method mapper for supplied klass and column,
  # and if suitable association found, process row data into current load_object
  def find_and_process(klass, column_name, row_data)
    method_detail = MethodMapper.find_method_detail( klass, column_name )

   
    if(method_detail)
      process(method_detail, row_data)
    else
      @load_object.errors.add_base( "No matching method found for column #{column_name}")
    end
  end

  
  def load( input, options = {} )
    raise "WARNING- ABSTRACT METHOD CALLED - Please implement load()"
  end

  # What process a value string from a column.
  # Assigning value(s) to correct association on @load_object.
  # Method detail represents a column from a file and it's correlated AR associations.
  # Value string which may contain multiple values for a collection association.
  # 
  def process(method_detail, value)
    #puts "INFO: LOADER BASE processing #{@load_object}"
    @current_value = value
    @current_method_detail = method_detail

    if(method_detail.operator_for(:has_many))

      if(method_detail.operator_class && @current_value)

        # there are times when we need to save early, for example before assigning to
        # has_and_belongs_to associations which require the load_object has an id for the join table
        
        save if( load_object.valid? && load_object.new_record? )

        # A single column can contain multiple associations delimited by special char
        columns = @current_value.split(@@multi_assoc_delim)

        # Size:large|Colour:red,green,blue   => generates find_by_size( 'large' ) and find_all_by_colour( ['red','green','blue'] )

        columns.each do |assoc|
          operator, values = assoc.split(@@name_value_delim)

          lookups = values.split(@@multi_value_delim)

          if(lookups.size > 1)

            @current_value = method_detail.operator_class.send("find_all_by_#{operator}", lookups )

            unless(lookups.size == @current_value.size)
              found = @current_value.collect {|f| f.send(operator) }
              @load_object.errors.add( method_detail.operator, "Association with key(s) #{(lookups - found).inspect} NOT found")
              puts "WARNING: Association with key(s) #{(lookups - found).inspect} NOT found - Not added."
              next if(@current_value.empty?)
            end

          else

            @current_value = method_detail.operator_class.send("find_by_#{operator}", lookups )

            unless(@current_value)
              @load_object.errors.add( method_detail.operator, "Association with key #{lookups} NOT found")
              puts "WARNING: Association with key #{lookups} NOT found - Not added."
              next
            end

          end

          # Lookup Assoc's Model done, now add the found value(s) to load model's collection
          method_detail.assign(@load_object, @current_value)
        end
      end
      # END HAS_MANY
    else
      # Nice n simple straight assignment to a column variable
      method_detail.assign(@load_object, @current_value)
    end
  end

  def save
    begin
      @load_object.save
    rescue => e
      @failed_objects << load_object
      puts e.inspect
      raise "Error processing #{@current_method_detail.name}"
    end
  end

  def find_or_new( klass, condition_hash = {} )
    @records[klass] = klass.find(:all, :conditions => condition_hash)
    if @records[klass].any?
      return @records[klass].first
    else
      return klass.new
    end
  end
  
end