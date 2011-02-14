# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Feb 2011
# License::   TBD. Free, Open Source. MIT ?
#
# Usage from rake : ruby -S rake image_load input=path_to_images
#
# => rake image_load input=vendor\extensions\autotelik\lib\fixtures\
# => rake image_load input="C:\images\01 Paintings photos large' dummy=true
# => rake image_load input="C:\images\taxon_icons" skip_if_no_assoc=true klass=Taxon

namespace :autotelik do

  desc "Populate the DB with images.\nSpecify full path with :input or a dir under ../db/image_seeds with :folder "
  # :dummy => dummy run without actual saving to DB
  task :image_load, :input, :folder, :dummy, :sku, :skip_if_no_assoc, :klass, :needs => :environment do |t, args|

    require 'image_loader'

    raise "USAGE: Please specify one of :input or :folder" if(args[:input] && args[:folder])
    puts  "SKU not specified " if(args[:input] && args[:folder])

    if args[:input]
      @image_cache = args[:input]
    else
      @image_cache =  File.join(RAILS_ROOT, "/vendor/extensions/site/db/image_seeds")
      @image_cache =  File.join(@image_cache, args[:folder]) if(args[:folder])
    end

    klazz= args[:klass] ? Kernal.const_get(args[:klass]) : Product

    if(File.exists? @image_cache )
      puts "Loading images from #{@image_cache}"

      missing_records = []
      Dir.glob("#{@image_cache}/*.{jpg,png,gif}") do |@image_name|

        puts "Processing #{@image_name} : #{File.exists?(@image_name)}"
        base_name = File.basename(@image_name, '.*')

        record = nil
        if args[:sku]
          sku = base_name.slice!(/\w+/)
          sku.strip!
          base_name.strip!

          puts "Looking fo SKU #{sku}"
          record = Variant.find_by_sku(sku)
          if record
            record = record.product   # SKU stored on Variant but we want it's master Product
          else
            puts "Looking for NAME [#{base_name}]"
            record = klazz.find_by_name(base_name)
          end
        else
          puts "Looking for #{klazz.name} with NAME [#{base_name}]"
          record = klazz.find_by_name(base_name)
        end
      
        if record
          puts "FOUND: #{record.inspect}"
        else
          missing_records << @image_name
        end

        # Now do actual upload to DB unless we are doing a dummy run,
        # or the Image has to have an associated record( Product )
        unless(args[:dummy] == 'true' || (args[:skip_if_no_assoc] && record.nil?))
          image_loader = ImageLoader.new
          image_loader.process( @image_name, record )
        end

      end

      unless missing_records.empty?
        FileUtils.mkdir_p('MissingRecords') unless File.directory?('MissingRecords')
        
        puts '\nMISSING Records Report>>'
        missing_records.each do |i|
          puts "Copy #{i} to MissingRecords folder"
          FileUtils.cp( i, 'MissingRecords')  unless(args[:dummy] == 'true')
        end
      end

    else
      puts "ERROR: Supplied Path #{@image_cache} not accesible"
      exit(-1)
    end
  end

  desc "Consistently rename a folder of files"
  task :file_rename, :input, :offset, :prefix, :width, :commit, :mv do |t, args|
    raise "USAGE: rake file_rename input='C:\Downloads\03 Daniel jpegs large 2010 copy' [offset=n prefix='str' width=n]" unless args[:input] && File.exists?(args[:input])
    width = args[:width] || 2

    action = args[:mv] ? 'mv' : 'cp'

    @image_cache = args[:input]

    if(File.exists? @image_cache )
      puts "Rename images from #{@image_cache}"
      Dir.glob(File.join(@image_cache, "*")) do |@image_name|
        path, base_name = File.split(@image_name)
        sku = base_name.slice!(/\w+/)

        sku = sku.to_i + args[:offset].to_i if(args[:offset])
        sku = "%0#{width}d" % sku.to_i
        sku = args[:prefix] + sku.to_s if(args[:prefix])

        destination = File.join(path, "#{sku}#{base_name}")
        puts "ACTION: #{action} #{@image_name} #{destination}"

        File.send( action, @image_name, destination) if args[:commit]
      end
    end
  end

end