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
  
  require 'loader_base'
  require 'method_mapper'

  require 'java'
  require 'jexcel_file'

  class ExcelLoader < LoaderBase

    attr_reader :headers
  
    def initialize(klass, object = nil, options = {})
      super( klass, object, options )
      raise "Cannot load - failed to create a #{klass}" unless @load_object
    end

    def load( file_name, options = {} )

      @excel = JExcelFile.new

      @excel.open(file_name)

      sheet_number = options[:sheet_number] || 0

      @sheet = @excel.sheet( sheet_number )

      header_row =  options[:header_row] || 0
      @header_row = @sheet.getRow(header_row)

      raise "ERROR: No headers found - Check Sheet #{@sheet} is completed sheet and Row 1 contains headers" unless @header_row

      @headers = []
      (0..JExcelFile::MAX_COLUMNS).each do |i|
        cell = @header_row.getCell(i)
        break unless cell
        @headers << "#{@excel.cell_value(cell).to_s}".strip
      end

      # Gather list of all possible 'setter' methods on AR class (instance variables and associations)
      MethodMapper.find_operators( load_object_class )

      @method_mapper = MethodMapper.new

      # Convert the list of headers into suitable calls on the Active Record class
      @method_mapper.find_all_method_details( load_object_class, @headers )

      unless(@method_mapper.missing_methods.empty?)
        raise MappingDefinitionError, "ERROR: Missing mappings for column headings #{@method_mapper.missing_methods.inspect}"
      end

      #if(options[:verbose])
      puts "\n\n\nLoading from Excel file: #{file_name}"
      puts "Processing #{@excel.num_rows} rows"
      # end

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
          @method_mapper.methods.each_with_index do |method_detail, col|

            value = value_at(row, col)

            contains_data = true unless(value.nil? || value.to_s.empty?)

            #puts "METHOD #{method_detail.inspect}"
            #puts "VALUE  #{value.inspect}"

            process(method_detail, value)
          end

          break unless contains_data

          # TODO - handle when it's not valid ?
          # Process rest and dump out an exception list of Products ??

          puts "SAVING ROW #{row} : #{load_object.inspect}" #if options[:verbose]
          if( load_object.valid? && load_object.save)
            @loaded_objects << load_object
          else
            @failed_objects << load_object
            puts load_object.errors.inspect
            puts load_object.errors.full_messages.inspect
            raise "Error processing row #{row} - Save failed : #{load_object.inspect}"
          end

          # don't forget to reset the object or we'll update rather than create
          new_load_object
        
        end
      end
    end

    def value_at(row, column)
      @excel.value( @excel.sheet.getRow(row), column)
    end
    
  end
end