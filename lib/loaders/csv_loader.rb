# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specific loader to support CSV files.
# 
#
require 'loaders/loader_base'
require 'ar_loader/exceptions'
require 'ar_loader/method_mapper'

module ARLoader
     
  class CsvLoader < LoaderBase
  
    def initialize(klass, object = nil, options = {})
      super( klass, object, options )
      raise "Cannot load - failed to create a #{klass}" unless @load_object
    end


    def load(file_name, options = {})

      require "csv"

      # TODO - abstract out what a 'parsed file' is - so a common object can represent excel,csv etc
      # then  we can make load() more generic
      
      @parsed_file = CSV.read(file_name)


      @headers = @parsed_file.shift

      @method_mapper = ARLoader::MethodMapper.new

      # Convert the list of headers into suitable calls on the Active Record class
      @method_mapper.populate_methods( load_object_class, @headers )

      unless(@method_mapper.missing_methods.empty?)
        puts "WARNING: Following column headings could not be mapped : #{@method_mapper.missing_methods.inspect}"
        raise MappingDefinitionError, "ERROR: Missing mappings for #{@method_mapper.missing_methods.size} column headings"
      end

      #if(options[:verbose])
      puts "\n\n\nLoading from CSV file: #{file_name}"
      puts "Processing #{@parsed_file.size} rows"
      # end

      load_object_class.transaction do
        @loaded_objects =  []

        @parsed_file.each do |row|
      
          # TODO - Smart sorting of column processing order ....
          # Does not currently ensure mandatory columns (for valid?) processed first but model needs saving
          # before associations can be processed so user should ensure mandatory columns are prior to associations

          # as part of this we also attempt to save early, for example before assigning to
          # has_and_belongs_to associations which require the load_object has an id for the join table

          # Iterate over the columns method_mapper found in Excel,
          # pulling data out of associated column
          @method_mapper.method_details.each_with_index do |method_detail, col|

            value = row[col]

            process(method_detail, value)
          end

          # TODO - handle when it's not valid ?
          # Process rest and dump out an exception list of Products ??

          puts "SAVING ROW #{row} : #{load_object.inspect}" #if options[:verbose]

          save

          # don't forget to reset the object or we'll update rather than create
          new_load_object

        end
      end

    end

  end
end