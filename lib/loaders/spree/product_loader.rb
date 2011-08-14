# Copyright:: (c) Autotelik Media Ltd 2010
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT ?
#
# Details::   Specific over-rides/additions to support Spree Products
#
require 'loader_base'
require 'excel_loader'
require 'product'

class ProductLoader < ExcelLoader

  def initialize(klass = Product, product = nil)
    super( klass, product )
    raise "Failed to create Product for loading" unless @load_object
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

    elsif(method_map.name == 'count_on_hand' && @load_object.variants.size > 0 && @value.is_a?(String) && @value.include?(@@multi_assoc_delim))
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