# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specific loader to support Excel files.
#             Note this only requires JRuby, Excel not required, nor Win OLE
#
require 'ar_loader/exceptions'

if(Guards::jruby?)


  require 'loaders/loader_base'
  require 'ar_loader/method_mapper'

  require 'java'
  require 'jexcel_file'

  module ARLoader
     
    class ExcelLoader < LoaderBase
  
      def initialize(klass, object = nil, options = {})
        super( klass, object, options )
        raise "Cannot load - failed to create a #{klass}" unless @load_object
      end
      

      def load( file_name, options = {} )

        @mandatory = options[:mandatory] || nil

        @excel = JExcelFile.new

        @excel.open(file_name)

        sheet_number = options[:sheet_number] || 0

        @sheet = @excel.sheet( sheet_number )

        header_row =  options[:header_row] || 0
        @header_row = @sheet.getRow(header_row)

        raise "ERROR: No headers found - Check Sheet #{@sheet} is completed sheet and Row 1 contains headers" unless(@header_row)

        @headers = []
        (0..JExcelFile::MAX_COLUMNS).each do |i|
          cell = @header_row.getCell(i)
          break unless cell
          header = "#{@excel.cell_value(cell).to_s}".strip
          break if header.empty?
          @headers << header
        end

        raise "ERROR: No headers found - Check Sheet #{@sheet} is completed sheet and Row 1 contains headers" if(@headers.empty?)


        @method_mapper = ARLoader::MethodMapper.new

        # Convert the list of headers into suitable calls on the Active Record class
        @method_mapper.populate_methods( load_object_class, @headers )

        unless(@method_mapper.missing_methods.empty?)
          puts "WARNING: Following column headings could not be mapped : #{@method_mapper.missing_methods.inspect}"
          raise MappingDefinitionError, "ERROR: Missing mappings for #{@method_mapper.missing_methods.size} column headings"
        end

        unless(@method_mapper.contains_mandatory?( options[:mandatory]) )
          missing_mandatory( options[:mandatory]).each { |e| puts "ERROR: Mandatory column missing - need a '#{e}' column" }
          raise "Bad File Description - Mandatory columns missing  - please fix and retry."
        end if(options[:mandatory])

        #if(options[:verbose])
        puts "\n\n\nLoading from Excel file: #{file_name}"

        load_object_class.transaction do
          @loaded_objects =  []

          (1..@excel.num_rows).collect do |row|

            # Excel num_rows seems to return all 'visible' rows, which appears to be greater than the actual data rows
            # (TODO - write spec to process .xls with a huge number of rows)
            #
            # So currently we have to manually detect when actual data ends, this isn't very smart but
            # currently got no better idea than ending once we hit the first completely empty row
            break if @excel.sheet.getRow(row).nil?

            contains_data = false

            # TODO - Smart sorting of column processing order ....
            # Does not currently ensure mandatory columns (for valid?) processed first but model needs saving
            # before associations can be processed so user should ensure mandatory columns are prior to associations

            # as part of this we also attempt to save early, for example before assigning to
            # has_and_belongs_to associations which require the load_object has an id for the join table

            # Iterate over the columns method_mapper found in Excel,
            # pulling data out of associated column
            @method_mapper.method_details.each_with_index do |method_detail, col|

              value = value_at(row, col)

              contains_data = true unless(value.nil? || value.to_s.empty?)

              #puts "DEBUG: Excel process METHOD :#{method_detail.inspect}"
              #puts "DEBUG: Excel process VALUE  :#{value.inspect}"
              process(method_detail, value)
            end

            break unless contains_data

            # TODO - requirements to handle not valid ?
            # all or nothing or carry on and dump out the exception list at end

            save

            # don't forget to reset the object or we'll update rather than create
            new_load_object
        
          end
        end
        puts "Excel loading stage complete - #{loaded_objects.size} rows added."
      end

      def value_at(row, column)
        @excel.value( @excel.sheet.getRow(row), column)
      end
    
    end
  end
end