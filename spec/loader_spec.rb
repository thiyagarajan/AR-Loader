# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for base class Loader
#
require File.dirname(__FILE__) + '/spec_helper'

require 'erb'

describe 'Basic Loader' do

  before(:all) do
    db_connect( 'test_file' )    # , test_memory, test_mysql
    migrate_up
    @klazz = Project
  end
  
  before(:each) do
    MethodMapper.clear
    MethodMapper.find_operators( @klazz )
  end
  
  it "should be able to create a new loader and load object" do
    loader = LoaderBase.new( @klazz )

    loader.load_object.should_not be_nil
    loader.load_object.should be_is_a(@klazz)
    loader.load_object.new_record?.should be_true
  end

  it "should process a string field against an assigment method detail" do

    loader = LoaderBase.new(Project)

    column = 'Value As String'
    row = 'Another Lazy fox '

    loader.find_and_process(@klazz, column, row)

    loader.load_object.value_as_string.should == row
  end

  it "should process a text field against an assigment method detail" do

    loader = LoaderBase.new(Project)

    column = :value_as_text
    row = "Another Lazy fox\nJumped over something and bumped,\nHis head"

    loader.find_and_process(@klazz, column, row)

    loader.load_object.value_as_text.should == row

  end

  it "should process a boolean field against an assigment method detail" do

    loader = LoaderBase.new(Project)

    column = :value_as_boolean
    row = true

    loader.find_and_process(@klazz, column, row)

    loader.load_object.value_as_boolean.should == row

    row = 'false'

    loader.find_and_process(@klazz, column, row)

    loader.load_object.value_as_boolean.should == false


  end

  it "should process a double field against an assigment operator" do
  end

  it "should process various date formats against a date assigment operator" do

    loader = LoaderBase.new(Project)

    column = :value_as_datetime

    loader.find_and_process(@klazz, column, Time.now)
    loader.load_object.value_as_datetime.should_not be_nil

    loader.find_and_process(@klazz, column, "2011-07-23")
    loader.load_object.value_as_datetime.should_not be_nil

    loader.find_and_process(@klazz, column, "Sat Jul 23 09:01:56 +0100 2011")
    loader.load_object.value_as_datetime.should_not be_nil

    loader.find_and_process(@klazz, column,  Time.now.to_s(:db))
    loader.load_object.value_as_datetime.should_not be_nil

    loader.find_and_process(@klazz, column,  "Jul 23 2011 23:02:59")
    loader.load_object.value_as_datetime.should_not be_nil

    loader.find_and_process(@klazz, column,  "07/23/2011")    # dd/mm/YYYY
    loader.load_object.value_as_datetime.should_not be_nil

    # bad casts
    loader.find_and_process(@klazz, column, "2011 07 23")
    loader.load_object.value_as_datetime.should be_nil


    loader.find_and_process(@klazz, column,  "2011-23-07")
    loader.load_object.value_as_datetime.should be_nil

    puts loader.load_object.value_as_datetime
  end

end