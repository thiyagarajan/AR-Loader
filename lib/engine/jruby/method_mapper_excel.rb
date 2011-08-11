# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Jan 2011
# License::   MIT
#
# JAVA SPECIFIC LOAD
require 'java'
require 'rubygems'
require 'jexcel_file'
require 'method_mapper'

class MethodMapperExcel < MethodMapper
    
  attr_accessor :excel, :sheet

  # Read the headers from a spreadsheet and map to ActiveRecord members/associations

  def initialize( file_name, klass, sheet_number = 0 )
    super()
    
    @excel = JExcelFile.new

    @excel.open(file_name)

    @sheet = @excel.sheet( sheet_number )

    @header_row = @sheet.getRow(0)

    raise "ERROR: No headers found - Check Sheet #{@sheet} is completed sheet and Row 1 contains headers" unless @header_row

    @headers = []
    (0..JExcelFile::MAX_COLUMNS).each do |i|
      cell = @header_row.getCell(i)
      break unless cell
      @headers << "#{@excel.cell_value(cell).to_s}".strip
    end

    # Gather list of all possible 'setter' methods on AR class (instance variables and associations)
    MethodMapperExcel.find_operators( klass )

    # Convert the list of headers into suitable calls on the Active Record class
    find_method_details( klass, @headers )
  end


  def value( row, column)
    @excel.value( @excel.sheet.getRow(row), column)
  end

  def num_rows
    @excel.num_rows
  end
end