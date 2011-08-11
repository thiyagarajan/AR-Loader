# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/spec_helper'

require 'erb'
require 'excel_loader'

describe 'Excel Loader' do

  before(:all) do
    db_connect( 'test_file' )    # , test_memory, test_mysql
    migrate_up
    @klazz = TestModel
    @assoc_klazz = TestAssociationModel
  end
  
  before(:each) do
    MethodMapper.clear
    MethodMapper.find_operators( @klazz )
    MethodMapper.find_operators( @assoc_klazz )
  end
  
  it "should be able to create a new excel loader and load object" do
    loader = ExcelLoader.new( TestModel)

    loader.load_object.should_not be_nil
    loader.load_object.should be_is_a(TestModel)
    loader.load_object.new_record?.should be_true
  end

  it "should process an excel spreedsheet" do

    loader = ExcelLoader.new(TestModel)

    loader.load( $fixture_path + '/DemoTestModel.xls')
  end

end