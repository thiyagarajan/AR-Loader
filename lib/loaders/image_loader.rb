# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Jan 2011
# License::   TBD. Free, Open Source. MIT ?
#
require 'loader_base'

class ImageLoader < LoaderBase

  def initialize(image = nil)
    obj = image || Image.create
    super( obj )
    raise "Failed to create Image for loading" unless @load_object
  end


  # Note the Spree Image model sets default storage path to
  # => :path => ":rails_root/public/assets/products/:id/:style/:basename.:extension"

  def process( image_path, record = nil)

    return unless File.exists?(image_path)

    alt = (record and record.respond_to? :name) ? record.name : ""

    @load_object.alt = alt

    begin
      @load_object.attachment = File.new(image_path, "r")
    rescue => e
      puts e.inspect
      puts "ERROR : Failed to read image #{image_path}"
      return
    end

    @load_object.attachment.reprocess!
    @load_object.viewable = record if record

    puts @load_object.save ? "Image: #{@load_object.inspect} added successfully" : "Problem saving image: #{@load_object}"
  end
end