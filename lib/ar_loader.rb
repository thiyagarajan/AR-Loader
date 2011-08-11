# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   TBD. Free, Open Source. MIT ?
#
# Details::   Active Record Loader
#
require 'active_record'
require 'rbconfig'

module Guards

  def self.jruby?
    return RUBY_PLATFORM == "java"
  end
  def self.mac?
    RbConfig::CONFIG['target_os'] =~ /darwin/i
  end

  def self.linux?
    RbConfig::CONFIG['target_os'] =~ /linux/i
  end

  def self.windows?
    RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
  end

end

module ArLoader

  def self.gem_version
    @gem_version ||= File.read( File.join( root_path, 'lib', 'VERSION') ).chomp
    @gem_version
  end

  def self.gem_name
    "ar_loader"
  end

  def self.root_path
    File.expand_path("#{File.dirname(__FILE__)}/..")
  end


  def self.require_libraries

    loader_libs = %w{ lib  }

    # Base search paths - these will be searched recursively and any xxx.rake files autoimported
    loader_paths = []

    loader_libs.each {|l| loader_paths << File.join(root_path(), l) }

    # Define require search paths, any dir in here will be added to LOAD_PATH

    loader_paths.each do |base|
      $:.unshift base  if File.directory?(base)
      Dir[File.join(base, '**', '**')].each do |p|
        if File.directory? p
          $:.unshift p
        end
      end
    end

    require__libs = %w{ loaders engine }

    require__libs.each do |base|
      Dir[File.join('lib', base, '*.rb')].each do |rb|
          unless File.directory? rb
            require rb
          end
      end
    end

  end

  def self.load_tasks
    # Long parameter lists so ensure rake -T produces nice wide output
    ENV['RAKE_COLUMNS'] = '180'
    base = File.join(root_path, 'tasks', '**')
    Dir["#{base}/*.rake"].sort.each { |ext| load ext }
  end
  
end

loaded ||= ArLoader::require_libraries