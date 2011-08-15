# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Feb 2011
# License::   MIT. Free, Open Source.
#
# REQUIRES:   JRuby access to Java
#
# Usage::
#
# e.g.  => jruby -S rake ar_loader:spree:products input=vendor/extensions/autotelik/fixtures/SiteSpreadsheetInfo.xls
#       => jruby -S rake ar_loader:spree:products input=C:\MyProducts.xls verbose=true
#
require 'ar_loader'
require 'product_loader'
require 'csv_loader'

namespace :ar_loader do

  namespace :spree do

    desc "Populate Spree db with Product/Variant data from .xls (Excel) file"
    task :products, [:input, :verbose, :sku_prefix] => :environment do |t, args|

      input = ENV['input']

      raise "USAGE: jruby -S rake  ar_loader:spree:products input=excel_file.xls" unless input
      raise "ERROR: Could not find file #{args[:input]}" unless File.exists?(input)

      require 'product_loader'

      # COLUMNS WITH DEFAULTS - TODO create YAML configuration file to drive defaults etc

      ARLoader::MethodDetail.set_default_value('available_on', Time.now.to_s(:db) )
      ARLoader::MethodDetail.set_default_value('cost_price', 0.0 )

      ARLoader::MethodDetail.set_prefix('sku', args[:sku_prefix] ) if args[:sku_prefix]

      if(File.extname(input) == '.xls' and Guards::jruby?)
        loader = ARLoader::ProductLoader.new
      else
        loader = ARLoader::CSVLoader.new
      end

      puts "Loading from file: #{input}"

      loader.load(input, :mandatory => ['sku', 'name', 'price'] )
    end
  end 

end