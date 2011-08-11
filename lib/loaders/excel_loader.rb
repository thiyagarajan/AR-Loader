# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specific loader to support Excel files.
#             Note this only requires JRuby, Excel not required, or Win OLE
#
require 'loader_base'
require 'method_mapper_excel'

class ExcelLoader < LoaderBase

  def initialize(klass, object = nil)
    super( klass, object )
    raise "Cannot load - failed to create a #{klass}" unless @load_object
  end

  def load( input, options = {} )

    @method_mapper = MethodMapperExcel.new(input, load_object_class)

    #if(options[:verbose])
    puts "Loading from Excel file: #input}"
    puts "Processing #{@method_mapper.num_rows} rows"
    # end

    load_object_class.transaction do
      @loaded_objects =  []

      (1..@method_mapper.num_rows).collect do |row|

        # Excel num_rows returns all 'visible' rows so,
        # we have to manually detect when actual data ends, this isn't very smart but
        # currently got no better idea than ending once we hit the first completely empty row
        break if @method_mapper.excel.sheet.getRow(row).nil?

        contains_data = false

        # TODO - Smart sorting of column processing order ....
        # Does not currently ensure mandatory columns (for valid?) processed first but model needs saving
        # before associations can be processed so user should ensure mandatory columns are prior to associations

        # Iterate over the columns method_mapper found in Excel,
        # pulling data out of associated column
        @method_mapper.methods.each_with_index do |method_detail, col|

          value = @method_mapper.value(row, col)

          contains_data = true if(value.to_s.empty?)

          puts "METHOD #{method_detail.class} #{method_detail.inspect}"
          puts "VALUE #{value} #{value.inspect}"

          process(method_detail, value)

          begin
            load_object.save if( load_object.valid? && load_object.new_record? )
          rescue
            raise "Error processing row"
          end
        end

        break unless contains_data

        loaded_object = load_object()

        # TODO - handle when it's not valid ?
        # Process rest and dump out an exception list of Products
        #unless(product.valid?)
        #end

        puts "SAVING ROW #{row} : #{loaded_object.inspect}" if args[:verbose]

        unless(loaded_object.save)
          puts loaded_object.errors.inspect
          puts loaded_object.errors.full_messages.inspect
          raise "Error Saving : #{loaded_object.inspect}"
        else
          @loaded_objects << loaded_object
        end
      end
    end
  end


  # What process a value string from a column, assigning value(s) to correct association on Product.
  # Method map represents a column from a file and it's correlated Product association.
  # Value string which may contain multiple values for a collection association.
  # Product to assign that value to.
  def process( method_map, value)
    #puts "INFO: PRODUCT LOADER processing #{@load_object}"
    @value = value

    #puts "DEBUG : process #{method_map.inspect} : #{value.inspect}"
    # Special case for OptionTypes as it's two stage process
    # First add the possible option_types to Product, then we are able
    # to define Variants on those options.
    
    if(method_map.name == 'option_types' && @value)

      option_types = @value.split(@@multi_assoc_delim)
      option_types.each do |ostr|
        oname, value_str = ostr.split(@@name_value_delim)
        option_type = OptionType.find_or_create_by_name(oname)
        unless option_type
          puts "WARNING: OptionType #{oname} NOT found - Not set Product"
          next
        end

        @load_object.option_types << option_type unless @load_object.option_types.include?(option_type)

        # Now get the value(s) for the option e.g red,blue,green for OptType 'colour'
        ovalues = value_str.split(',')
        ovalues.each_with_index do |ovname, i|
          ovname.strip!
          ov = OptionValue.find_by_name(ovname)
          if ov
            object = Variant.new( :sku => "#{@load_object.sku}_#{i}", :price => @load_object.price, :available_on => @load_object.available_on)
            #puts "DEBUG: Create New Variant: #{object.inspect}"
            object.option_values << ov
            @load_object.variants << object
          else
            puts "WARNING: Option #{ovname} NOT FOUND - No Variant created"
          end
        end
      end

      # Special case for ProductProperties since it can have additional value applied.
      # A list of Properties with a optional Value - supplied in form :
      #   Property:value|Property2:value|Property3:value
      #
    elsif(method_map.name == 'product_properties' && @value)

      property_list = @value.split(@@multi_assoc_delim)

      property_list.each do |pstr|
        pname, pvalue = pstr.split(@@name_value_delim)
        property = Property.find_by_name(pname)
        unless property
          puts "WARNING: Property #{pname} NOT found - Not set Product"
          next
        end
        @load_object.product_properties << ProductProperty.create( :property => property, :value => pvalue)
      end

    elsif(method_map.name == 'count_on_hand' && @load_object.variants.size > 0 &&
          @value.is_a?(String) && @value.include?(@@multi_assoc_delim))
      # Check if we processed Option Types and assign count per option
      values = @value.split(@@multi_assoc_delim)
      if(@load_object.variants.size == values.size)
        @load_object.variants.each_with_index {|v, i| v.count_on_hand == values[i] }
      else
        puts "WARNING: Count on hand entries does not match number of Variants"
      end

    else
      super(method_map, value)
    end

  end
end