require 'active_support'
require 'active_record'
require 'erb'

require File.dirname(__FILE__) + '/../lib/ar_loader'


#.# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Spec Helper for Active Record Loader
#
#
# We are not setup as a Rails project so need to mimic an active record database setup so
# we have some  AR models top test against. Create an in memory database from scratch.
#

def db_connect( env = 'test_file')

  # Some active record stuff seems to rely on the RAILS_ENV being set ?

  ENV['RAILS_ENV'] = env
  
  configuration = {}

  configuration[:database_configuration] = YAML::load(ERB.new(IO.read( File.dirname(__FILE__) + '/database.yml')).result)
  db = configuration[:database_configuration][ env ]

  puts "Setting DB Config - #{db.inspect}"
  ActiveRecord::Base.configurations = db

  #ActiveRecord::Base.logger = Logger.new(STDOUT)

  puts "Connecting to DB"
  ActiveRecord::Base.establish_connection( db )

  require 'logger'
  ActiveRecord::Base.logger = Logger.new(STDOUT)

  #puts "Connected to DB - #{ActiveRecord::Base.connection.inspect}"

  require File.dirname(__FILE__) + '/fixtures/models'

  # handle migration changes or reset of test DB
  migrate_up

end

def db_clear
  [Project, Milestone, Category, Version, Release].each {|x| x.delete_all}
end

def load_in_memory
  load "#{Rails.root}/db/schema.rb"
end

def migrate_up
  ActiveRecord::Migrator.up(  File.dirname(__FILE__) + '/db/migrate')
end


$fixture_path = File.join(File.dirname(__FILE__), 'fixtures')

RSpec.configure do |config|
  # config.use_transactional_fixtures = true
  # config.use_instantiated_fixtures  = false
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures'

  # You can declare fixtures for each behaviour like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so here, like so ...
  #
  #   config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
end