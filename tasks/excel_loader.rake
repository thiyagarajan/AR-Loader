# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Feb 2011
# License::   TBD. Free, Open Source. MIT ?
#
# REQUIRES:   JRuby
#
# Usage::
# => jruby -S rake ar_loader:excel_load model=<active record class> input=<file.xls>
# => jruby -S rake ar_loader:excel_load model=<active record class> input=C:\MyProducts.xlsverbose=true
#
namespace :ar_loader do

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
      loader = ExcelLoader.new(klass)
    end

    loader.load(args[:input])

#    require 'method_mapper_excel'
#
#    @method_mapper = MethodMapperExcel.new(args[:input], klass)
#
#    @excel = @method_mapper.excel
#
#    if(args[:verbose])
#      puts "Loading from Excel file: #{args[:input]}"
#      puts "Processing #{@excel.num_rows} rows"
#    end

    # Process spreadsheet and create model instances

  
    end   # TRANSACTION

  end

end