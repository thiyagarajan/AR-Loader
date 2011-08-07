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
    db_connect( 'test_file' )    # , test_memory, test_mysql
    migrate_up
    @klazz = TestModel
  end
  
  before(:each) do
    @row = TestModel.create( :value_as_string => 'I am a String', :value_as_text => "I am lots\n of text", :value_as_boolean => true)
    #:value_as_datetime, :default => nil
    @klazz = TestModel

    MethodMapper.clear
    MethodMapper.find_operators( @klazz )
  end
  
  it "should populate operators for a given AR model" do

    MethodMapper.has_many.should_not be_empty
    MethodMapper.has_many[TestModel].should include('TestAssociationModel')

    MethodMapper.assignments.should_not be_empty
    MethodMapper.assignments[TestModel].should include('id')
    MethodMapper.assignments[TestModel].should include('value_as_string')
    MethodMapper.assignments[TestModel].should include('value_as_text')

    MethodMapper.belongs_to.should_not be_empty
    MethodMapper.belongs_to[TestModel].should be_empty


    MethodMapper.column_types.should be_is_a(Hash)
    MethodMapper.column_types.should_not be_empty
    MethodMapper.column_types[TestModel].size.should == TestModel.columns.size

  end

  it "should find method details correctly for different forms of a column name" do

    [:value_as_string, 'value_as_string', "VALUE as_STRING", "value as string"].each do |format|

      method_details = MethodMapper.find_method_detail( @klazz, format )

      method_details.class.should == MethodDetail

      puts method_details.inspect

      method_details.operator.should == 'value_as_string'
      method_details.assignment.should == 'value_as_string'
      method_details.operator_for(:assignment).should == 'value_as_string'

      method_details.operator_for(:belongs_to).should be_nil
      method_details.operator_for(:has_many).should be_nil

      method_details.belongs_to.should be_nil
      method_details.has_many.should be_nil


      method_details.col_type.should_not be_nil
      method_details.col_type.name.should == 'value_as_string'
      method_details.col_type.default.should == nil
      method_details.col_type.sql_type.should include 'varchar(255)'   # db specific, sqlite
      method_details.col_type.type.should == :string
    end
  end

end