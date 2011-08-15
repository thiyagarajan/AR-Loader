# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
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
# => jruby -S rake ar_loader:csv model=<active record class> input=<file.csv>
#
namespace :ar_loader do

  desc "Populate a model's table in db with data from CSV file"
  task :csv, [:model, :loader, :input, :verbose] => [:environment] do |t, args|

    # in familiar ruby style args seems to have been become empty with rake 0.9.2 whatever i try
    # so had to revert back to ENV
    model = ENV['model']
    input = ENV['input']
   
    raise "USAGE: jruby -S rake ar_loader:excel input=excel_file.xls model=<Class>" unless(input)
    raise "ERROR: Cannot process without AR Model - please supply model=<Class>" unless(model)
    raise "ERROR: Could not find file #{args[:input]}" unless File.exists?(input)

    begin
      klass = Kernel.const_get(model)
    rescue NameError
      raise "ERROR: No such AR Model found - check valid model supplied via model=<Class>"
    end

    puts "INFO: Using CSV loader"
    
    loader = CsvLoader.new(klass)

    loader.load(input)
  end

end