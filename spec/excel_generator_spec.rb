# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/spec_helper'

require 'erb'
require 'excel_generator'

include ARLoader

describe 'Excel Generator' do

  before(:all) do
    db_connect( 'test_file' )    # , test_memory, test_mysql

    db_clear()    # todo read up about proper transactional fixtures


    @klazz = Project
    @assoc_klazz = Category
  end
  
  before(:each) do
    MethodMapper.clear
    MethodMapper.find_operators( @klazz )
    MethodMapper.find_operators( @assoc_klazz )
  end
  
  it "should be able to create a new excel generator" do
    generator = ExcelGenerator.new( )
  end
  
  it "should export a simple model to .xls spreedsheet" do

    expect= $fixture_path + '/simple_export_spec.xls'

    begin FileUtils.rm(expect); rescue; end
  
    gen = ExcelGenerator.new
    
    gen.generate(@klazz, expect)
 
    File.exists?(expect).should be_true

  end

  
end