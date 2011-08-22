# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
# An Excel file helper. Create and populate XSL files
#
# The maximum number of columns and rows in an Excel file is fixed at 256 Columns and 65536 Rows
# 
# POI jar location needs to be added to class path.
#
#  TODO -  Check out http://poi.apache.org/poi-ruby.html
#
if(Guards::jruby?)

  class Object
    def add_to_classpath(path)
      $CLASSPATH << File.join( ArLoader.root_path, 'lib', path.gsub("\\", "/") )
    end
  end

  require 'java'
  require 'rubygems'

  add_to_classpath 'java/poi-3.6.jar'

  class JExcelFile
    include_class 'org.apache.poi.poifs.filesystem.POIFSFileSystem'
    include_class 'org.apache.poi.hssf.usermodel.HSSFCell'
    include_class 'org.apache.poi.hssf.usermodel.HSSFWorkbook'
    include_class 'org.apache.poi.hssf.usermodel.HSSFCellStyle'
    include_class 'org.apache.poi.hssf.usermodel.HSSFDataFormat'

    include_class 'java.io.ByteArrayOutputStream'
    include_class 'java.util.Date'
    include_class 'java.io.FileInputStream'

    attr_accessor :book, :row, :current_sheet
  
    attr_reader   :sheet

    MAX_COLUMNS = 256.freeze
    MAX_ROWS = 65536.freeze

    # The HSSFWorkbook uses 0 based indexes
  
    def initialize()
      @book = nil
    end

    def open(filename)
      inp = FileInputStream.new(filename)

      @book = HSSFWorkbook.new(inp)

      sheet(0)  # also sets @current_sheet
    end

    # TOFIX - how do we know which sheet we are creating so we can set index @current_sheet
    def create_sheet(sheet_name)
      @book = HSSFWorkbook.new()
      @sheet = @book.createSheet(sheet_name.gsub(" ", ''))
      date_style = @book.createCellStyle()
      date_style.setDataFormat(HSSFDataFormat.getBuiltinFormat("m/d/yy h:mm"))
      @sheet
    end

    # Return the current or specified HSSFSheet
    def sheet(i = nil)
      @current_sheet = i if i
      @sheet = @book.getSheetAt(@current_sheet)
      @sheet
    end

    def num_rows
      @sheet.getPhysicalNumberOfRows
    end

    # Process each row. (type is org.apache.poi.hssf.usermodel.HSSFRow)

    def each_row
      @sheet.rowIterator.each { |row| yield row }
    end


    # Create new row
    def create_row(index)
      @row = @sheet.createRow(index)
      @row
    end
  
    def set_cell(row, column, data)
      @row = @sheet.getRow(row) || create_row(row)
      @row.createCell(column).setCellValue(data)
    end

    def value(row, column)
      raise TypeError, "Expect row argument of type HSSFRow" unless row.is_a?(Java::OrgApachePoiHssfUsermodel::HSSFRow)
      #puts "DEBUG - CELL VALUE : #{column} => #{ cell_value( row.getCell(column) ).inspect}"
      cell_value( row.getCell(column) )
    end
  
    def cell_value(cell)
      return nil unless cell
      #puts "DEBUG CELL TYPE : #{cell} => #{cell.getCellType().inspect}"
      case (cell.getCellType())
      when HSSFCell::CELL_TYPE_FORMULA  then return cell.getCellFormula()
      when HSSFCell::CELL_TYPE_NUMERIC  then return cell.getNumericCellValue()
      when HSSFCell::CELL_TYPE_STRING   then return cell.getStringCellValue()
      when HSSFCell::CELL_TYPE_BOOLEAN  then return cell.getBooleanCellValue()
      when HSSFCell::CELL_TYPE_BLANK    then return ""
      end
    end
  
    def save( filename )
      File.open( filename, 'w') {|f| f.write(to_s) }
    end


    # The internal representation of a Excel File
  
    def to_s
      outs = ByteArrayOutputStream.new
      @book.write(outs);
      outs.close();
      String.from_java_bytes(outs.toByteArray)
    end
 
  end
  
end