# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT.
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
# => jruby -S rake ar_loader:gen:excel model=<active record class> result=<output_template.xls>
#
namespace :ar_loader do
  namespace :gen do

    desc "Generate a template .xls (Excel) file for a model"
  
    task :excel, [:model, :result] => [:environment] do |t, args|

      require 'excel_generator'
      
      # in familiar ruby style args seems to have been become empty using this new style for rake 0.9.2
      #  whatever format i try, on both Win and OSX .. so had to revert back to ENV
      model = ENV['model']
      result = ENV['result']
    
      raise "USAGE: jruby -S rake ar_loader:gen:excel model=<Class> result=<file.xls>" unless(result)
      raise "ERROR: Cannot process without AR Model - please supply model=<Class>" unless(model)

      begin
        klass = Kernel.const_get(model)
      rescue NameError
        raise "ERROR: No such AR Model found - check valid model supplied via model=<Class>"
      end

      gen = ARLoader::ExcelGenerator.new

      gen.generate(klass, result)
    end

  end
end