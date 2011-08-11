# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
# Details::   A base class that stores details of all possible associations on AR classes and,
#             given user supplied class and name, attempts to find correct attribute/association.
#
#             Derived classes define where the user supplied list of names originates from.
#
#             Example usage, load from a spreadsheet where the column names are only
#             an approximation of the actual associations. Given a column heading of
#             'Product Properties' on class Product,  find_method_detail() would search AR model,
#             and return details of real has_many association 'product_properties'.
#
#             This real association can then be used to send spreadsheet row data to the AR object.
#             
require 'method_detail'

class MethodMapper

  attr_accessor :header_row, :headers
  attr_accessor :methods
  
  @@has_many     = Hash.new
  @@belongs_to   = Hash.new
  @@assignments  = Hash.new
  @@column_types = Hash.new

  def initialize
    @methods = []
    @headers = []
  end

  # Build complete picture of the methods whose names listed in method_list
  # Handles method names as defined by a user or in file headers where names may
  # not be exactly as required e.g handles capitalisation, white space, _ etc
  
  def find_method_details( klass, method_list )
    @methods = method_list.collect { |x| MethodMapper::find_method_detail( klass, x ) }
    @methods.compact!
  end

  def method_names()
    @methods.collect( &:name )
  end

  def check_mandatory( mandatory_list )
    method_list = method_names()

    mandatory_list.select { |x| x unless(method_list.index(x)) }
  end

  # Create picture of the operators for assignment available on an AR model,
  # including via associations (which provide both << and = )
  #
  def self.find_operators(klass, options = {} )

    # Find the has_many associations which can be populated via <<
    if( options[:reload] || @@has_many[klass].nil? )
      @@has_many[klass] = klass.reflect_on_all_associations(:has_many).map { |i| i.name.to_s }
      klass.reflect_on_all_associations(:has_and_belongs_to_many).inject(@@has_many[klass]) { |x,i| x << i.name.to_s }
    end
    # puts "DEBUG: Has Many Associations:", @@has_many[klass].inspect

    # Find the belongs_to associations which can be populated via  Model.belongs_to_name = OtherArModelObject
    if( options[:reload] || @@belongs_to[klass].nil? )
      @@belongs_to[klass] = klass.reflect_on_all_associations(:belongs_to).map { |i| i.name.to_s }
    end

    #puts "Belongs To Associations:", @@belongs_to[klass].inspect

    # Find the model's column associations which can be populated via = value
    if( options[:reload] || @@assignments[klass].nil? )
      @@assignments[klass] = (klass.column_names + klass.instance_methods.grep(/=/).map{|i| i.gsub(/=/, '')})
      @@assignments[klass] = @@assignments[klass] - @@has_many[klass] if(@@has_many[klass])
      @@assignments[klass] = @@assignments[klass] - @@belongs_to[klass] if(@@belongs_to[klass])
      
      @@assignments[klass].uniq!

      @@assignments[klass].each do |assign|
        @@column_types[klass] ||= {}
        found = klass.columns.find{ |col| col.name == assign }
        @@column_types[klass].merge!( found.name => found) if found
      end
    end
  end

  # Find the proper format of name, appropriate call + column type for a given name.
  # e.g Given users entry in spread sheet check for pluralization, missing underscores etc
  #
  # If not nil, returned method can be used directly in for example klass.new.send( call, .... )
  #
  def self.find_method_detail( klass, external_name )
    assign, belongs_to, has_many = nil, nil, nil

    name = external_name.to_s

    # TODO - check out regexp to do this work better plus Inflections ??
    # Want to be able to handle any of ["Count On hand", 'count_on_hand', "Count OnHand", "COUNT ONHand" etc]
    [
      name,
      name.tableize,
      name.gsub(' ', '_'),
      name.gsub(' ', ''),
      name.gsub(' ', '_').downcase,
      name.gsub(' ', '').downcase,
      name.gsub(' ', '_').underscore].each do |n|
      
        assign     = (assignments_for(klass).include?(n))?  n : nil
          break if assign
        has_many   = (has_many_for(klass).include?(n))   ?  n : nil
          break if has_many
        belongs_to = (belongs_to_for(klass).include?(n)) ?  n : nil
          break if belongs_to

    end

    if(assign || belongs_to || has_many)
      return MethodDetail.new(klass, name, assign, belongs_to, has_many, @@column_types[klass])
    end

    nil
  end

  def self.clear
    @@belongs_to.clear
    @@has_many.clear
    @@assignments.clear
    @@column_types.clear
  end

  def self.column_key(klass, column)
    "#{klass.name}:#{column}"
  end

  # TODO - remove use of class variables - not good Ruby design
  def self.belongs_to
    @@belongs_to
  end
  def self.has_many
    @@has_many
  end
  def self.assignments
    @@assignments
  end
  def self.column_types
    @@column_types
  end


  def self.belongs_to_for(klass)
    @@belongs_to[klass] || []
  end
  def self.has_many_for(klass)
    @@has_many[klass] || []
  end
  def self.assignments_for(klass)
    @@assignments[klass] || []
  end
  def self.column_type_for(klass, column)
    @@column_types[klass] ?  @@column_types[klass][column] : []
  end


  def find_or_new( klass, condition_hash = {} )
    @records[klass] = klass.find(:all, :conditions => condition_hash)
    if @records[klass].any?
      return @records[klass].first
    else
      return klass.new
    end
  end
  
end