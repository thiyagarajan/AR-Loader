# Copyright:: (c) Autotelik Media Ltd 2010
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT ?
#
# Details::   A helper class that stores details of all possible associations on an AR class
#             and given a user supplied name attempts to find the association.
#
#             Example usage, load from a file or spreadsheet where the column names are only
#             an approximation of the actual associations, so given 'Product Properties' heading,
#             finds real association 'product_properties' to send or call on the AR object
#             
require 'method_detail'

class MethodMapper

  attr_accessor :methods
  
  @@has_many     = Hash.new
  @@belongs_to   = Hash.new
  @@assignments  = Hash.new
  @@column_types = Hash.new

  def initialize
    @methods = []
  end

  # Build complete picture of the methods whose names listed in method_list
  # Handles method names as defined by a user or in file headers where names may
  # not be exactly as required e.g handles capitalisation, white space, _ etc
  
  def find_method_details( klass, method_list )
    @methods = method_list.collect { |x| MethodMapper::find_method_detail( klass, x ) }
  end

  def method_names()
    @methods.collect( &:name )
  end

  def check_mandatory( mandatory_list )
    method_list = method_names()

    mandatory_list.each { |x| raise "Mandatory column missing - need a '#{x}' column" unless(method_list.index(x)) }
  end

  # Create picture of the operators for assignment available on an AR model,
  # including via associations (which provide both << and = )
  #
  def self.find_operators(klass, options = {} )

    if( options[:reload] || @@has_many[klass].nil? )
      @@has_many[klass] = klass.reflect_on_all_associations(:has_many).map { |i| i.name.to_s }
      klass.reflect_on_all_associations(:has_and_belongs_to_many).inject(@@has_many[klass]) { |x,i| x << i.name.to_s }
    end

    # puts "DEBUG: Has Many Associations:", @@has_many[klass].inspect

    if( options[:reload] || @@belongs_to[klass].nil? )
      @@belongs_to[klass] = klass.reflect_on_all_associations(:belongs_to).map { |i| i.name.to_s }
    end

    # puts "DEBUG: Belongs To Associations:", @@belongs_to[klass].inspect

    if( options[:reload] || @@assignments[klass].nil? )
      @@assignments[klass] = (klass.column_names + klass.instance_methods.grep(/=/).map{|i| i.gsub(/=/, '')})
      @@assignments[klass] = @@assignments[klass] - @@has_many[klass] if(@@has_many[klass])
      @@assignments[klass] = @@assignments[klass] - @@belongs_to[klass] if(@@belongs_to[klass])
      
      @@assignments[klass].uniq!

      @@assignments[klass].each do |assign|
        found = klass.columns.find{ |col| col.name == assign }
        @@column_types[column_key(klass, assign)] = found if found
      end
    end
  end

  # Find the proper format of name, appropriate call + column type for a given name.
  # e.g Given users entry in spread sheet check for pluralization, missing underscores etc
  #
  # If not nil returned method can be used directly in for example klass.new.send( call, .... )
  #
  def self.find_method_detail( klass, name )
    true_name, assign, belongs_to, has_many = nil, nil, nil, nil
    
    # TODO - check out regexp to do this work better plus Inflections ??
    [
      name,
      name.gsub(' ', '_'),
      name.gsub(' ', ''),
      name.gsub(' ', '_').downcase,
      name.gsub(' ', '').downcase,
      name.gsub(' ', '_').underscore

    ].each do |n|
      has_many   = (@@has_many[klass]    && @@has_many[klass].include?(n))   ?  n : nil
      belongs_to = (@@belongs_to[klass]  && @@belongs_to[klass].include?(n)) ?  n : nil
      assign     = (@@assignments[klass] && @@assignments[klass].include?(n))?  n + '=' : nil

      if(assign || has_many || belongs_to)
        true_name = n
        break
      end
    end

    return MethodDetail.new(klass, true_name, assign, belongs_to, has_many, @@column_types[column_key(klass, true_name)])
  end

  def self.clear
    @@has_many.clear
    @@assignments.clear
    @@column_types.clear
  end

  def self.column_key(klass, column)
    "#{klass.name}:#{column}"
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

  def self.has_many_for(klass)
    @@has_many[klass]
  end
  def self.assignments_for(klass)
    @@assignments[klass]
  end

  def self.column_type_for(klass, column)
    @@column_types[column_key(klass, column)]
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