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

  desc "Populate the database with Product data stored in Excel"
  task :excel_load, :input, :verbose, :sku_prefix, :needs => :environment do |t, args|
  
    require 'product_loader'
    require 'method_mapper_excel'

    raise "USAGE: jruby -S rake excel_load input=excel_file.xls" unless args[:input] && File.exists?(args[:input])
    raise "ERROR: Could not find file #{args[:input]}" unless File.exists?(args[:input])

    @method_mapper = MethodMapperExcel.new(args[:input], Product)

    @excel = @method_mapper.excel

    if(args[:verbose])
      puts "Loading from Excel file: #{args[:input]}"
      puts "Processing #{@excel.num_rows} rows"
    end

    # REQUIRED 'set' methods on Product i.e will not validate/save without these
    required_methods = ['sku', 'name', 'price']

    @method_mapper.check_mandatory( required_methods )

    # COLUMNS WITH DEFAULTS - TODO create YAML configuration file to drive defaults etc
  
    MethodDetail.set_default_value('available_on', Time.now.to_s(:db) )
    MethodDetail.set_default_value('cost_price', 0.0 )

    MethodDetail.set_prefix('sku', args[:sku_prefix] ) if args[:sku_prefix]

    # Process spreadsheet and create Products
    method_names = @method_mapper.method_names

    sku_index = method_names.index('sku')

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
        # Does not currently ensure mandatory columns (for valid?) processed first but Product needs saving
        # before associations can be processed so user should ensure SKU, name, price columns are among first columns

        @method_mapper.methods.each_with_index do |method_map, col|
          product_data_row.getCell(col).setCellType(JExcelFile::HSSFCell::CELL_TYPE_STRING) if(col == sku_index)
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