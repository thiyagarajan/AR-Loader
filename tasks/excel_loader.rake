# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Feb 2011
# License::   TBD. Free, Open Source. MIT ?
#
# REQUIRES:   JRuby
#
# Usage from rake : jruby -S rake excel_loader input=<file.xls>
#
# e.g.  => jruby -S rake excel_load input=vendor\extensions\autotelik\fixtures\ExampleInfoWeb.xls
#       => jruby -S rake excel_load input=C:\MyProducts.xls verbose=true
#
namespace :autotelik do

  desc "Populate AR model's table with data stored in Excel"
  task :excel_load, :klass, :input, :verbose, :sku_prefix, :needs => :environment do |t, args|

    raise "USAGE: jruby -S rake excel_load input=excel_file.xls" unless args[:input]
    raise "ERROR: Cannot process without AR Model - please supply model=<Class>" unless args[:class]
    raise "ERROR: Could not find file #{args[:input]}" unless File.exists?(args[:input])

    klass =  Kernal.const_get(args[:model])
    raise "ERROR: No such AR Model found - please check model=<Class>" unless(klass)

    require 'product_loader'
    require 'method_mapper_excel'

    args[:class]

    @method_mapper = MethodMapperExcel.new(args[:input], Product)

    @excel = @method_mapper.excel

    if(args[:verbose])
      puts "Loading from Excel file: #{args[:input]}"
      puts "Processing #{@excel.num_rows} rows"
    end

    # TODO create YAML configuration file to drive mandatory columns
    #
    # TODO create YAML configuration file to drive defaults etc
  
    # Process spreadsheet and create model instances
    
    method_names = @method_mapper.method_names

    Product.transaction do
      @products =  []

      (1..@excel.num_rows).collect do |row|

        product_data_row = @excel.sheet.getRow(row)
        break if product_data_row.nil?

        # Excel num_rows seems to return all 'visible' rows so,
        # we have to manually detect when actual data ends and all the empty rows start
        contains_data = required_methods.find { |mthd| ! product_data_row.getCell(method_names.index(mthd)).to_s.empty? }
        break unless contains_data
 
        @assoc_classes = {}

        loader = ProductLoader.new()

        # TODO - Smart sorting of column processing order ....
        # Does not currently ensure mandatory columns (for valid?) processed first but model needs saving
        # before associations can be processed so user should ensure mandatory columns are prior to associations

        @method_mapper.methods.each_with_index do |method_map, col|

          loader.process(method_map, @excel.value(product_data_row, col))
          begin
            loader.load_object.save if( loader.load_object.valid? && loader.load_object.new_record? )
          rescue
            raise "Error processing Product"
          end
        end

        product = loader.load_object

        product.available_on ||= Time.now.to_s(:db)

        # TODO - handle when it's not valid ? 
        # Process rest and dump out an exception list of Products
        #unless(product.valid?)
        #end

        puts "SAVING ROW #{row} : #{product.inspect}" if args[:verbose]

        unless(product.save)
          puts product.errors.inspect
          puts product.errors.full_messages.inspect
          raise "Error Saving Product: #{product.sku} :#{product.name}"
        else
          @products << product
        end
      end
    end   # TRANSACTION

  end

end