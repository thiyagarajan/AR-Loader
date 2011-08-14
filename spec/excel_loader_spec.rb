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

    db_clear()    # todo read up about proper transactional fixtures


    @klazz = Project
    @assoc_klazz = Category
  end
  
  before(:each) do

    Project.delete_all
    
    %w{category_001 category_002 category_003}.each do |c|
      @assoc_klazz.find_or_create_by_name(c)
    end

    MethodMapper.clear
    MethodMapper.find_operators( @klazz )
    MethodMapper.find_operators( @assoc_klazz )
  end
  
  it "should be able to create a new excel loader and load object" do
    loader = ExcelLoader.new( @klazz)
    
    loader.load_object.should_not be_nil
    loader.load_object.should be_is_a(@klazz)
    loader.load_object.new_record?.should be_true
  end
  
  it "should process a simple .xls spreedsheet" do
  
    loader = ExcelLoader.new(@klazz)
 
    count = @klazz.count
    loader.load( $fixture_path + '/SimpleProjects.xls')
  
    loader.loaded_count.should == (@klazz.count - count)
  
  end

  it "should process associations in .xls spreedsheet" do

    @klazz.find_by_title('001').should be_nil
    count = @klazz.count

    loader = ExcelLoader.new(@klazz)
    
    loader.load( $fixture_path + '/DemoTestModelAssoc.xls')

    loader.loaded_count.should be > 3
    loader.loaded_count.should == (@klazz.count - count)

    {'001' => 2, '002' => 1, '003' => 3, '004' => 0 }.each do|title, expected|
      project = @klazz.find_by_title(title)

      project.should_not be_nil
      puts "#{project.inspect} [#{project.categories.size}]"
      
      project.should have(expected).categories
    end
  end

  it "should process multiple associations in excel spreedsheet" do
  
    loader = ExcelLoader.new(Project)
  
    count = Project.count
    loader.load( $fixture_path + '/ProjectsMultiCategories.xls')
  
    loader.loaded_count.should == (Project.count - count)
  
    {'004' => 3, '005' => 1, '006' => 0, '007' => 1 }.each do|title, expected|
      project = @klazz.find_by_title(title)
  
      project.should_not be_nil
      puts "#{project.inspect} [#{project.categories.size}]"

      project.should have(expected).categories
    end
  
  end
  
  it "should not process badly defined excel spreedsheet" do
    loader = ExcelLoader.new(Project)
    expect {loader.load( $fixture_path + '/BadAssociationName.xls')}.to raise_error(MappingDefinitionError)
  end

end