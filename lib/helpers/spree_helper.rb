# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Spree Helper mixing in Support for testing or loading Rails Spree e-commerce.
# 
#             Since ar_loader gem is not a Rails app or a Spree App, provides utilities to internally
#             create a Spree Database, and to load Spree components, enabling standalone testing.
#
module Spree


  def self.root
    Gem.loaded_specs['spree_core'] ? Gem.loaded_specs['spree_core'].full_gem_path  : ""
  end

  def self.lib_root
    File.join(root, 'lib')
  end

  def self.app_root
    File.join(root, '/app')
  end

  def self.load
    gem 'rails'
    
    gem 'spree'
    require 'spree'

    gem 'paperclip'
    gem 'nested_set'

    require 'nested_set'
    require 'paperclip'
    require 'acts_as_list'

    CollectiveIdea::Acts::NestedSet::Railtie.extend_active_record
    ActiveRecord::Base.send(:include, Paperclip::Glue)

    gem 'activemerchant'
    require 'active_merchant'
    require 'active_merchant/billing/gateway'

    ActiveRecord::Base.send(:include, ActiveMerchant::Billing)

    $LOAD_PATH << lib_root << app_root << File.join(app_root, 'models')

    load_models
    
    Dir[lib_root + '/*.rb'].each do |r|
      begin
        require r if File.file?(r)  
      rescue => e
      end
    end

    Dir[lib_root + '/**/*.rb'].each do |r|
      begin
        require r if File.file?(r) && ! r.include?('testing')  && ! r.include?('generators')
      rescue => e
      end
    end

    load_models
  end

  def self.load_models
    puts 'load from', root
    Dir[root + '/app/models/**/*.rb'].each {|r|
      begin
        require r if File.file?(r)
      rescue => e
        puts 'failed to load', r, e.inspect
      end
    }
  end

  def self.migrate_up
    load
    ActiveRecord::Migrator.up( File.join(root, 'db/migrate') )
  end

end
