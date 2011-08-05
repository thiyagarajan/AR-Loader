# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/spec_helper'

require 'erb'

class TestModel < ActiveRecord::Base
  has_many :TestAssociationModel
end

class TestAssociationModel < ActiveRecord::Base
  belongs_to :test_model
end

describe 'ExcelLoader' do

  before(:all) do
    db_connect( 'test_mysql' )
    migrate_up
  end
  
  before(:each) do
    @row = TestModel.create( :value_as_string => 'I am a String', :value_as_text => "I am lots\n of text", :value_as_boolean => true)
    
      #:value_as_datetime, :default => nil
    puts "YES TABLE:" if TestModel.table_exists?
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

#  it "should populate operators respecting unique option" do
#    MethodMapper.find_operators( @klazz, :unique => true )
#
#    hmf = MethodMapper.has_many_for(@klazz)
#    arf = MethodMapper.assignments_for(@klazz)
#
#    (hmf & arf).should be_empty
#  end
#
#  it "should populate assignment method and col type for different forms of a column name" do
#
#    MethodMapper.find_operators( @klazz )
#  end
#
#  it "should populate both methods for different forms of an association name" do
#
#    MethodMapper.find_operators( @klazz )
#  end
#
#  it "should not populate anything when  non existent column name" do
#    MethodMapper.find_operators( @klazz )
#  end
#
#  it "should enable correct assignment and sending of a value to AR model" do
#    MethodMapper.find_operators( @klazz )
#  end
#
#  it "should enable correct assignment and sending of association to AR model" do
#    MethodMapper.find_operators( @klazz )
#  end


end