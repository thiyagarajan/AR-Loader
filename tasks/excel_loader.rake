# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Feb 2011
# License::   TBD. Free, Open Source. MIT ?
#
# REQUIRES:   JRuby
#
# Usage::
#
#  In Rakefile:
#
#     require 'ar_loader'
#
#     ArLoader::load_tasks
#
#  Cmd Line:
#
# => jruby -S rake ar_loader:excel_load model=<active record class> input=<file.xls>
# => jruby -S rake ar_loader:excel_load model=<active record class> input=C:\MyProducts.xlsverbose=true
#
namespace :ar_loader do

  desc "Populate a model's table in db with data from .xls (Excel) file"
  #task :excel_load, :model, :loader, :input, :verbose, :needs => :environment do |t, args|
  task :excel_load, [:model, :loader, :input, :verbose] => [:environment] do |t, args|

    # in familiar ruby style args seems to have been become empty with rake 0.9.2 whatever i try
    # so had to revert back to ENV
    model = ENV['model']
    input = ENV['input']
    puts 'ARGS', args.inspect
    raise "USAGE: jruby -S rake ar_loader:excel input=excel_file.xls model=<Class>" unless(input)
    raise "ERROR: Cannot process without AR Model - please supply model=<Class>" unless(model)
    raise "ERROR: Could not find file #{args[:input]}" unless File.exists?(input)

    begin
      klass = Kernel.const_get(model)
    rescue NameError
      raise "ERROR: No such AR Model found - check valid model supplied via model=<Class>"
    end

    begin
      require "#{model}_loader"

      loader_klass = Kernel.const_get("#{model}Loader")

      loader = loader_klass.new(klass)
    rescue
      puts "INFO: No specific #{model}Loader found  - using generic ExcelLoader"
      loader = ExcelLoader.new(klass)
    end

    loader.load(input)
  end

end