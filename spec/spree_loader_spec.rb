unless defined? SPREE_ROOT
  ENV["RAILS_ENV"] = "test"
  case
  when ENV["SPREE_ENV_FILE"]
    require ENV["SPREE_ENV_FILE"]
  when File.dirname(__FILE__) =~ %r{vendor/SPREE/vendor/extensions}
    require "#{File.expand_path(File.dirname(__FILE__) + "/../../../../../../")}/config/environment"
  else
    require "#{File.expand_path(File.dirname(__FILE__) + "/../../../../")}/config/environment"
  end
end
require "#{SPREE_ROOT}/spec/spec_helper"

if File.directory?(File.dirname(__FILE__) + "/scenarios")
  Scenario.load_paths.unshift File.dirname(__FILE__) + "/scenarios"
end
if File.directory?(File.dirname(__FILE__) + "/matchers")
  Dir[File.dirname(__FILE__) + "/matchers/*.rb"].each {|file| require file }
end

require File.dirname(__FILE__) + '/spec_helper'

describe 'ExcelLoader' do

  before do
    @klazz = Product
    MethodMapper.clear
  end
  
  it "should populate operators for a given AR model" do
    MethodMapper.find_operators( @klazz )

    MethodMapper.has_many.should_not be_empty
    MethodMapper.assignments.should_not be_empty

    hmf = MethodMapper.has_many_for(@klazz)
    arf = MethodMapper.assignments_for(@klazz)

    (hmf & arf).should_not be_empty       # Associations provide << or =

    hmf.should include('properties')
    arf.should include('count_on_hand')   # example of a column
    arf.should include('cost_price')      # example of delegated assignment (available through Variant)

    MethodMapper.column_types.should be_is_a(Hash)
    MethodMapper.column_types.should_not be_empty

    MethodMapper.column_type_for(@klazz, 'count_on_hand').should_not be_nil
  end

  it "should populate operators respecting unique option" do
    MethodMapper.find_operators( @klazz, :unique => true )

    hmf = MethodMapper.has_many_for(@klazz)
    arf = MethodMapper.assignments_for(@klazz)

    (hmf & arf).should be_empty
  end

  it "should populate assignment method and col type for different forms of a column name" do

    MethodMapper.find_operators( @klazz )

    ["Count On hand", 'count_on_hand', "Count OnHand", "COUNT ONHand"].each do |format|
      mmap = MethodMapper.determine_calls( @klazz, format )

      mmap.class.should == MethodDetail

      mmap.assignment.should == 'count_on_hand='
      mmap.has_many.should be_nil

      mmap.col_type.should_not be_nil
      mmap.col_type.name.should == 'count_on_hand'
      mmap.col_type.default.should == 0
      mmap.col_type.sql_type.should == 'int(10)'
      mmap.col_type.type.should == :integer
    end
  end

  it "should populate both methods for different forms of an association name" do

    MethodMapper.find_operators( @klazz )
    ["product_option_types", "product option types", 'product Option_types', "ProductOptionTypes", "Product_Option_Types"].each do |format|
      mmap = MethodMapper.determine_calls( @klazz, format )

      mmap.assignment.should == 'product_option_types='
      mmap.has_many.should   == 'product_option_types'

      mmap.col_type.should be_nil
    end
  end


  it "should not populate anything when  non existent column name" do
    ["On sale", 'on_sale'].each do |format|
      mmap = MethodMapper.determine_calls( @klazz, format )

      mmap.class.should == MethodDetail
      mmap.assignment.should be_nil
      mmap.has_many.should be_nil
      mmap.col_type.should be_nil
    end
  end

  it "should enable correct assignment and sending of a value to AR model" do

    MethodMapper.find_operators( @klazz )
    
    mmap = MethodMapper.determine_calls( @klazz, 'count on hand' )
    mmap.assignment.should == 'count_on_hand='

    x = @klazz.new

    x.should be_new_record

    x.send( mmap.assignment, 2 )
    x.count_on_hand.should == 2
    x.on_hand.should == 2     # helper method I know looks at same thing

    mmap = MethodMapper.determine_calls( @klazz, 'SKU' )
    mmap.assignment.should == 'sku='
    x.send( mmap.assignment, 'TEST_SK 001' )
    x.sku.should == 'TEST_SK 001'
  end

  it "should enable correct assignment and sending of association to AR model" do

    MethodMapper.find_operators( @klazz )

    mmap = MethodMapper.determine_calls( @klazz, 'taxons' )
    mmap.has_many.should == 'taxons'

    x = @klazz.new

    # NEW ASSOCIATION ASSIGNMENT  v.,mn
    x.send( mmap.has_many ) << Taxon.new
    x.taxons.size.should == 1

    x.send( mmap.has_many ) << [Taxon.new, Taxon.new]
    x.taxons.size.should == 3

    # EXISTING ASSOCIATIONS
    x = Product.find :first

    t = Taxonomy.find_or_create_by_name( 'BlahSpecTest' )

    if x
      sz = x.taxons.size
      x.send(mmap.has_many) << t.root
      x.taxons.size.should == sz + 1
    else
      puts "WARNING : Test not run could not find any Test Products"
    end

  end


end