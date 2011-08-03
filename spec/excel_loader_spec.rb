require File.dirname(__FILE__) + '/spec_helper'

require 'erb'
require File.dirname(__FILE__) + '/../lib/ar_loader'

# We are not setup as a Rails project so need to mimic an active record database setup so
# we have some  AR models top test against. Create an in memory database from scratch.
# 
def db_connect( env = 'test')

  configuration = {:rails_env => env }

  # Some active record stuff seems to rely on the RAILS_ENV being set ?

  ENV['RAILS_ENV'] = configuration[:rails_env]

  configuration[:database_configuration] = YAML::load(ERB.new(IO.read( File.dirname(__FILE__) + '/database.yml')).result)
  db = configuration[:database_configuration][ configuration[:rails_env] ]

  puts "Setting DB Config - #{db.inspect}"
  ActiveRecord::Base.configurations = db

  puts "Connecting to DB"
  ActiveRecord::Base.establish_connection( db )

  puts "Connected to DB Config - #{configuration[:rails_env]}"
end

def create_in_memory_database
  ActiveRecord::Migrator.up('db/migrate')
end


class TestModel < ActiveRecord::Base
  has_many :TestAssociationModel
end

class TestAssociationModel < ActiveRecord::Base
  belongs_to :test_model
end

describe 'ExcelLoader' do

  before do
    db_connect
    create_in_memory_database
    @klazz = TestModel
    MethodMapper.clear
  end
  
  it "should populate operators for a given AR model" do
    MethodMapper.find_operators( @klazz )

    MethodMapper.has_many.should_not be_empty
    MethodMapper.assignments.should_not be_empty

    hmf = MethodMapper.has_many_for(@klazz)
    arf = MethodMapper.assignments_for(@klazz)

    (hmf & arf).should_not be_empty       # Associations provide << or =

    MethodMapper.column_types.should be_is_a(Hash)
    MethodMapper.column_types.should_not be_empty

  end

  it "should populate operators respecting unique option" do
    MethodMapper.find_operators( @klazz, :unique => true )

    hmf = MethodMapper.has_many_for(@klazz)
    arf = MethodMapper.assignments_for(@klazz)

    (hmf & arf).should be_empty
  end

  it "should populate assignment method and col type for different forms of a column name" do

    MethodMapper.find_operators( @klazz )
  end

  it "should populate both methods for different forms of an association name" do

    MethodMapper.find_operators( @klazz )
  end

  it "should not populate anything when  non existent column name" do
    MethodMapper.find_operators( @klazz )
  end

  it "should enable correct assignment and sending of a value to AR model" do
    MethodMapper.find_operators( @klazz )
  end

  it "should enable correct assignment and sending of association to AR model" do
    MethodMapper.find_operators( @klazz )
  end


end