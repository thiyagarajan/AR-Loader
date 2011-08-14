# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/spec_helper'

describe 'Method Mapping' do

  before(:all) do
    db_connect( 'test_file' )    # , test_memory, test_mysql
    migrate_up
    @klazz = Project
    @assoc_klazz = TestAssociationModel
  end
  
  before(:each) do
    MethodMapper.clear
    MethodMapper.find_operators( @klazz )
    MethodMapper.find_operators( @assoc_klazz )
  end
  
  it "should populate method map for a given AR model" do

    MethodMapper.has_many.should_not be_empty
    MethodMapper.has_many[Project].should include('test_association_models')

    MethodMapper.assignments.should_not be_empty
    MethodMapper.assignments[Project].should include('id')
    MethodMapper.assignments[Project].should include('value_as_string')
    MethodMapper.assignments[Project].should include('value_as_text')

    MethodMapper.belongs_to.should_not be_empty
    MethodMapper.belongs_to[Project].should be_empty


    MethodMapper.column_types.should be_is_a(Hash)
    MethodMapper.column_types.should_not be_empty
    MethodMapper.column_types[Project].size.should == Project.columns.size


  end

  it "should populate assigment members without the equivalent association names" do

    # we should remove has-many & belongs_to from basic assignment set as they require a DB lookup
    # or a Model.create call, not a simple assignment

    MethodMapper.assignments_for(@klazz).should_not include( MethodMapper.belongs_to_for(@klazz) )
    MethodMapper.assignments_for(@klazz).should_not include( MethodMapper.has_many_for(@klazz) )
  end


  it "should find method details for different forms of a column name" do
    MethodMapper.find_method_detail( @klazz, 'TestAssociationModels' ).class.should == MethodDetail
    MethodMapper.find_method_detail( @klazz, :test_association_models ).class.should == MethodDetail
    MethodMapper.find_method_detail( @klazz, 'test association models' ).class.should == MethodDetail
    MethodMapper.find_method_detail( @klazz, "Test Association Models" ).class.should == MethodDetail
    MethodMapper.find_method_detail( @klazz, 'Test Association_models' ).class.should == MethodDetail
    MethodMapper.find_method_detail( @klazz, 'Test association_models' ).class.should == MethodDetail
  end

  it "should find assignment operator for method details for different forms of a column name" do

    [:value_as_string, 'value_as_string', "VALUE as_STRING", "value as string"].each do |format|

      method_details = MethodMapper.find_method_detail( @klazz, format )

      method_details.class.should == MethodDetail

      method_details.name.should eq( format.to_s )

      method_details.operator.should == 'value_as_string'
      method_details.assignment.should == 'value_as_string'
      method_details.operator_for(:assignment).should == 'value_as_string'

      method_details.operator_for(:belongs_to).should be_nil
      method_details.operator_for(:has_many).should be_nil

      method_details.belongs_to.should be_nil
      method_details.has_many.should be_nil
    end
  end

  it "should find belongs_to operator for method details for different forms of a column name" do

    [:test_model, 'test MODEL', "test model", "test_model"].each do |format|

      method_details = MethodMapper.find_method_detail( @assoc_klazz, format )

      method_details.should_not be_nil

      result = 'test_model'
      method_details.operator.should == result
      method_details.belongs_to.should == result
      method_details.operator_for(:belongs_to).should == result

      method_details.operator_for(:assignment).should be_nil
      method_details.operator_for(:has_many).should be_nil

      method_details.assignment.should be_nil
      method_details.has_many.should be_nil
    end

  end


  it "should find has_many operator for method details" do

    [:test_association_models, "Test Association Models"].each do |format|

      method_details = MethodMapper.find_method_detail( @klazz, format )

      method_details.class.should == MethodDetail

      puts "Processing form", method_details.name
      
      result = 'test_association_models'
      method_details.operator.should == result
      method_details.has_many.should == result
      method_details.operator_for(:has_many).should == result

      method_details.operator_for(:belongs_to).should be_nil
      method_details.operator_for(:assignments).should be_nil

      method_details.assignment.should be_nil
      method_details.belongs_to.should be_nil
    end

  end

  it "should find association class for belongs_to operator method details" do

    [:test_model, 'test MODEL', "test model", "test_model"].each do |format|

      method_details = MethodMapper.find_method_detail( @assoc_klazz, format )

      method_details.operator_class_name.should == 'Project'
      method_details.operator_class.should == Project
    end

    [:value_as_string, 'value_as_string', "VALUE as_STRING", "value as string"].each do |format|

      method_details = MethodMapper.find_method_detail( @assoc_klazz, format )

      method_details.operator_class_name.should == 'String'
      method_details.operator_class.should be_is_a(Class)
      method_details.operator_class.should == String
    end


    [:test_association_models, "Test Association Models"].each do |format|
      method_details = MethodMapper.find_method_detail( @klazz, format )

      method_details.operator_class_name.should == 'TestAssociationModel'
      method_details.operator_class.should == TestAssociationModel
    end
  end


  # Note : Not all assignments will currently have a column type, for example
  # those that are derived from a delegate_belongs_to

  it "should populate column types in method details" do

    [:value_as_string, 'value_as_string', "VALUE as_STRING", "value as string"].each do |format|

      method_details = MethodMapper.find_method_detail( @klazz, format )

      method_details.class.should == MethodDetail

      method_details.col_type.should_not be_nil
      method_details.col_type.name.should == 'value_as_string'
      method_details.col_type.default.should == nil
      method_details.col_type.sql_type.should include 'varchar(255)'   # db specific, sqlite
      method_details.col_type.type.should == :string
    end
  end

  it "should return nil when non existent column name" do
    ["On sale", 'on_sale'].each do |format|
      detail = MethodMapper.find_method_detail( @klazz, format )

      detail.should be_nil
    end
  end


  it "should find a set of methods based on a list of column names" do

    mapper = MethodMapper.new

    [:value_as_string, 'value_as_string', "VALUE as_STRING", "value as string"].each do |format|

      method_details = MethodMapper.find_method_detail( @klazz, format )

      method_details.class.should == MethodDetail

      method_details.col_type.should_not be_nil
      method_details.col_type.name.should == 'value_as_string'
      method_details.col_type.default.should == nil
      method_details.col_type.sql_type.should include 'varchar(255)'   # db specific, sqlite
      method_details.col_type.type.should == :string
    end
  end

end