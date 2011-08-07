# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
# Details::   This class provides information and access to the individual methods
#             on an AR model. Populated by, and coupled with MethodMapper,
#             which does the model interrogation work.
#             Enables 'loaders' to iterate over the MethodMapper results set,
#             and assign values to AR object, without knowing anything about that receiving object.
#
# =>
require 'to_b'

class MethodDetail

  def self.type_enum
    @type_enum ||= Set[:has_many, :belongs_to, :assignment]
    @type_enum
  end

  # When looking up an association, try each of these in turn till a match
  #  i.e find_by_name .. find_by_title and so on
  @@insistent_find_by_list ||= [:id, :name, :title]

  # TODO refactor away these separate attribs and just have a type => value pair
  attr_accessor :klass, :name, :assignment, :col_type
  attr_accessor :has_many, :has_many_class_name, :has_many_class
  attr_accessor :belongs_to, :belongs_to_class_name, :belongs_to_class

  @@default_values = {}
  @@prefixes = {}

  # Return the actual operator's name for supplied method type
  def operator_for( type )
    return self.send(type) if( MethodDetail::type_enum.member?(type) )
    nil
  end

  # Return the actual operator's name
  def operator()
    puts "operator #{@operator}"
    @operator ||= operator_for(operator_type)
    @operator
  end

  # Return the supplied method type for the operator
  def operator_type()
    MethodDetail::type_enum.find{|x| operator_for(x); }
  end

  # Store the raw (client supplied) name against the mapped against
  def initialize(klass, name, assignment, belongs_to, has_many, col_types = {} )
    @klass, @name = klass, name
    @assignment, @has_many, @belongs_to = assignment, has_many, belongs_to

    @col_type = col_types[operator]
    
    if(@has_many)
      begin
        @has_many_class = Kernel.const_get(@has_many.classify)
        @has_many_class_name = @has_many.classify
      rescue
        # TODO - bomb out ?
      end
    end

    if(@belongs_to)
      begin
        @belongs_to_class = Kernel.const_get(@belongs_to.classify)
        @belongs_to_class_name = @belongs_to.classify
      rescue
        # TODO - try other forms of the name, set to nil, or bomb out ?
      end
    end
  end

  def assign( record, value )
    #puts "DEBUG: assign: [#{@name}]"

    data = value

    if(@@default_values[@name])
      puts "WARNING nil value supplied for [#{@name}] - Using default : [#{@@default_values[@name]}]"
      data = @@default_values[@name]
    else
      puts "WARNING nil value supplied for [#{@name}] - No default"
    end if(data.nil?)
    
    data = "#{@@prefixes[@name]}#{data}" if(@@prefixes[@name])

    if( @belongs_to )
      
      #puts "DEBUG : BELONGS_TO #{@belongs_to} - Lookup #{data} in DB"
      insistent_belongs_to(record, data)

    elsif( @has_many )

      puts "WARNING : generic has_many not currently supported"

    elsif( @assignment && @col_type )
      puts "DEBUG : COl TYPE defined for #{@name} : #{@assignment} => #{data} #{@col_type.inspect}"
      record.send( @assignment + '=' , @col_type.type_cast( data ) )

    elsif( @assignment )
      puts "DEBUG : No COL TYPE found for #{@name} : #{@assignment} => #{data}"
      insistent_assignment(record, data)
    end
  end

  # Attempt to find the associated object via id, name, title ....
  def insistent_belongs_to( record, value )

    @@insistent_find_by_list.each do |x|
      begin
        item = @belongs_to_class.send( "find_by_#{x}", value)
        if(item)
          record.send(@belongs_to + '=', item)
          break
        end
      rescue => e
        puts "ERROR: #{e.inspect}"
        if(x == @@insistent_method_list.last)
          raise "I'm sorry I have failed to assign [#{value}] to #{@assignment}" unless value.nil?
        end
      end
    end
  end

  def insistent_assignment( record, value )
    puts "DEBUG: RECORD CLASS #{record.class}"
    op = @assignment + '='
    
    @@insistent_method_list ||= [:to_s, :to_i, :to_f, :to_b]
    begin
      record.send(op, value)
    rescue => e
      puts e.inspect
      @@insistent_method_list.each do |f|
        begin

          record.send(op, value.send( f) )
          break
        rescue => e
          #puts "DEBUG: insistent_assignment: #{e.inspect}"
          if f == @@insistent_method_list.last
            puts  "I'm sorry I have failed to assign [#{value}] to #{@assignment}"
            raise "I'm sorry I have failed to assign [#{value}] to #{@assignment}" unless value.nil?
          end
        end
      end
    end
  end

  def self.set_default_value( name, value )
    @@default_values[name] = value
  end

  def self.default_value(name)
    @@default_values[name]
  end

  def self.set_prefix( name, value )
    @@prefixes[name] = value
  end

  def self.prefix_value(name)
    @@prefixes[name]
  end
  
  def pp
    "#{@name} => #{operator}"
  end
  
end
