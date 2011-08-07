# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Feb 2011
# License::   TBD. Free, Open Source. MIT ?
#
# REQUIRES:   JRuby
#
# Usage::
# => jruby -S rake autotelik:excel_load model=<active record class> input=<file.xls>
# => jruby -S rake autotelik:excel_load model=<active record class> input=C:\MyProducts.xlsverbose=true
#
namespace :autotelik do

  desc "Populate a model's table in db with data from .xls (Excel) file"
  task :excel_load, :model, :loader, :input, :verbose, :needs => :environment do |t, args|

    raise "USAGE: jruby -S rake excel_load input=excel_file.xls" unless args[:input]
    raise "ERROR: Cannot process without AR Model - please supply model=<Class>" unless args[:model]
    raise "ERROR: Could not find file #{args[:input]}" unless File.exists?(args[:input])

    begin
      klass = Kernel.const_get(args[:model])
    rescue NameError
      raise "ERROR: No such AR Model found - please check model=<Class>"
    end

    begin
      require "#{args[:model]}_loader"

      loader_klass = Kernel.const_get("#{args[:model]}Loader")

      loader = loader_klass.new(klass)
    rescue
      puts "INFO: No specific #{args[:model]}Loader found using generic loader"
      loader = LoaderBase.new(klass)
    end

    require 'method_mapper_excel'

    @method_mapper = MethodMapperExcel.new(args[:input], klass)

    @excel = @method_mapper.excel

    if(args[:verbose])
      puts "Loading from Excel file: #{args[:input]}"
      puts "Processing #{@excel.num_rows} rows"
    end

    # Process spreadsheet and create model instances
 
    klass.transaction do
      @loaded_objects =  []

      (1..@excel.num_rows).collect do |row|

        data_row = @excel.sheet.getRow(row)
        break if data_row.nil?

        @assoc_classes = {}

        # TODO - Smart sorting of column processing order ....
        # Does not currently ensure mandatory columns (for valid?) processed first but model needs saving
        # before associations can be processed so user should ensure mandatory columns are prior to associations

        contains_data = false

        # Iterate over the columns method_mapper found in Excel,
        # pulling data out of associated column
        @method_mapper.methods.each_with_index do |method_map, col|

          value = @excel.value(data_row, col)

          # Excel num_rows seems to return all 'visible' rows so,
          # we have to manually detect when actual data ends, this isn't very smart but
          # currently got no better idea than ending once we hit the first completely empty row
 
          contains_data = true if(value.to_s.empty?)

          puts "VALUE #{value.class}"
          puts "VALUE #{value} #{value.inspect}"

          loader.process(method_map, @excel.value(data_row, col))

          begin
            loader.load_object.save if( loader.load_object.valid? && loader.load_object.new_record? )
          rescue
            raise "Error processing row"
          end
        end

        break unless contains_data

        loaded_object = loader.load_object

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
    end   # TRANSACTION

  end

end