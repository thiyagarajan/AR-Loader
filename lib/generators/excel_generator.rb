# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Export a model to Excel
#
#
if(Guards::jruby?)

  require 'jexcel_file'
  require 'generator_base'

  module ARLoader


    class ExcelGenerator < GeneratorBase

      attr_accessor :excel
  

      def initialize
        @excel = nil
      end

  
      # Create an Excel file representing supplied Model
    
      def generate(model, filename)
   
        @excel = JExcelFile.new()

        sheet = @excel.create_sheet( model.name )

        @excel.create_row(0)

        MethodMapper.find_operators( model )

        # header row
        unless(MethodMapper.assignments[model].empty?)
          row = sheet.createRow(0)
          cell_index = 0
          MethodMapper.assignments[model].each do |operator|
            row.createCell(cell_index).setCellValue(operator)
            cell_index += 1
          end
        end
    
        @excel.save( filename )
      end

  
      def to_xls(items=[])

        # value rows
        row_index = 1
        items.each do |item|
          row = sheet.createRow(row_index);

          cell_index = 0
          item.class.columns.each do |column|
            cell = row.createCell(cell_index)
            if column.sql_type =~ /date/ then
              millis = item.send(column.name).to_f * 1000
              cell.setCellValue(Date.new(millis))
              cell.setCellStyle(dateStyle);
            elsif column.sql_type =~ /int/ then
              cell.setCellValue(item.send(column.name).to_i)
            else
              value = item.send(column.name)
              cell.setCellValue(item.send(column.name)) unless value.nil?
            end
            cell_index += 1
          end
          row_index += 1
        end
        @excel.to_s
      end
    end
 
  end
end # jruby