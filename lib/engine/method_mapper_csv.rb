# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Jan 2011
# License::   MIT
#
# Details::   Extract the headings from a user supplied CSV file, and map heading names
#             to the attributes and/or assocaiitons of an AR Model defined by supplied klass.
#
require 'method_mapper'

class MethodMapperCsv < MethodMapper
    
  # Read the headers from CSV file and map to ActiveRecord members/associations

  def initialize( file_name, klass, sheet_number = 0 )
    super
    
    File.open(file_name) do
      @headers =  @header_row.split(/,/)
    end

    # Gather list of all possible 'setter' methods on AR class (instance variables and associations)
    self.find_operators( klass )

    # Convert the list of headers into suitable calls on the Active Record class
    find_method_details( klass, @headers )
  end
end