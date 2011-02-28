# Copyright:: (c) Autotelik Media Ltd 2011
# Author::    Tom Statter
# Date::      April 2010
#
# Details::   Summit BO File splitting utils.
#
#             Utilises shared/file_definitions to enable intelligent splitting of
#             input and output files, with optional filtering of values.
#
# == Usage:

namespace :files do

  desc "Split a file, defined by klass, on supplied field. For Usage: help=true"

  task :split, :klass, :input, :on, :filter, :sort, :results, :help, :needs => [:start_logging] do |t, args|

    require 'fo_triple_file_def'

    klasses = FileDefinitions::subclasses

    begin
      klass = Kernel::const_get(args[:klass])
    rescue
      help = true
    end

    usage=<<-EOU
      Please provide file definitions via:      klass=[#{klasses.join('|')}]
      Please provide field to split on via:     on=[name]
      Please provide input file to process via: input=<path>
    EOU

    help = true unless klass && args[:on] && args[:input]

    if(help || args[:help])
      puts "\n#### USAGE: ####\n", usage
      if klass
        puts "Available fields to split on:\n #{klass.field_definition.inspect}"
      else
        puts "To list available split fields pass: help=true klass=<file def class>"
      end
      puts "\nOptional filter on records to include can be supplied via argument: filter=<regexp>"
      puts "\tExample:\t\ton=Ccy filter='GBP|USD'"
      exit
    end

    file_input = args[:input]

    log :info, "Processing file [#{file_input}]"

    raise BadConfigError.new( "Please provide valid file with input=<path>") unless( file_input && File.readable?(file_input))

    log :info, "Processing file [#{file_input}]"

    opts = {}     # Cannot simply pass args (TaskArgs class which doesn't convert to Hash)
    opts[:filter] = args[:filter] if args[:filter]
    opts[:sort]   = String::to_boolean(args[:sort])

    klass.split_on_write(file_input, args[:on], args[:results], opts )

    log :info, "Finished"
  end

  # == Usage:
  #
  # =>    Rake change_field field=available_on value=20110101 set=20110214 klass=Product input=shoplist.csv results=.
  #
  require 'mappingfile_definitions'


  desc "Change a field in a file - For further help: Rake change_field help=true"

  task :change_field, :klass, :input, :on, :map_file, :from, :to, :filter, :help, :results, :out, :needs => [:start_logging] do |t, args|

    klasses = FileDefinitions::subclasses

    usage=<<-EOU
      Please provide file definitions via:      klass=[#{klasses.join('|')}]
      Please provide field to change via:       on=[field:[,field2,...]]
      Please provide input file to process via: input=[path]
      Please provide value mappings via:        map_file=[path]
      OR
      Please provide value to replace via:      from=[old value]
      Please provide value to replace with via: to=[new value]
    EOU

    begin
      klass = Kernel::const_get(args[:klass])
    rescue
      help = true
    end

    help = true unless( klass && args[:on] && args[:input] && (args[:from] && args[:to] || args[:map_file]))

    if(help || args[:help])
      puts "\n#### USAGE: ####\n", usage
      if klass
        puts "Available fields to split on:\n #{klass.field_definition.inspect}"
      else
        puts "To list available split fields pass: help=true klass=<file def class>"
      end

      puts "Replaces values matching 'from' value, and also accepts an optional filter"
      puts "for more powerful matching strategies of values on the specified field."

      exit 0
    end

    input_file = args[:input]
    raise BadConfigError.new( "Cannot read provided file ") unless File.readable?(input_file)

    log :info, "Processing file [#{input_file}]"

    if(args[:map_file])
      map = ValueMapFromFile.new
      map.load_map(args[:map_file])

      data, klass_objects = klass::file_set_field_by_map(input_file, args[:on], map)
    else
      data, klass_objects = klass::file_set_field(input_file, args[:on], args[:from], args[:to], args[:filter] )
    end

    w = RecsBase.new
    w.results = (args[:results] || '.')

    w.write( (args[:out] || "change_full_#{args[:on]}.out")  => klass_objects.collect(&:to_s).join("\n") )
    w.write( "change_keys_#{args[:on]}.out" => data.join("\n") ) if(args[:keys])

    log :debug, data.inspect

  end
end