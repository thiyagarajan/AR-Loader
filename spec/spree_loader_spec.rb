require File.dirname(__FILE__) + '/spec_helper'

require 'spree'

require 'spree_loader'

describe 'SpreeLoader' do

  before(:all) do
    db_connect( 'test_file' )    # , test_memory, test_mysql
    Spree.load
    Spree.migrate_up
  end

  before do
    @klazz = Product
    MethodMapper.clear
    MethodMapper.find_operators( @klazz )

    # TOFIX - weird error
    # NameError:
    #   undefined local variable or method `check_price' for #<Variant:0x1031f6658>
    # but that method defined on Variant class in variant.rb

    #@product = Product.new( :sku => "TRspec001", :name => 'Test RSPEC Product', :price => 99.99 )
    #@product.save
  end
  
  it "should populate operators for a Spree Product" do
  
    MethodMapper.has_many.should_not be_empty
    MethodMapper.belongs_to.should_not be_empty
    MethodMapper.assignments.should_not be_empty


    assign = MethodMapper.assignments_for(@klazz)

    assign.should include('count_on_hand')   # Example of a simple column
    assign.should include('cost_price')      # Example of delegated assignment (available through Variant)

    MethodMapper.assignments[@klazz].should include('cost_price')

    has_many_ops = MethodMapper.has_many_for(@klazz)

    has_many_ops.should include('properties')   # Product can have many properties

    MethodMapper.has_many[@klazz].should include('properties')

    btf = MethodMapper.belongs_to_for(@klazz)

    btf.should include('tax_category')    # Example of a belongs_to assignment

    MethodMapper.belongs_to[@klazz].should include('tax_category')


    MethodMapper.column_types.should be_is_a(Hash)
    MethodMapper.column_types.should_not be_empty
    MethodMapper.column_types[@klazz].size.should == @klazz.columns.size
  end

  it "should populate assigment without associations" do
    
    # we should remove has-many & belongs_to from basic assignment set as they require a DB lookup
    # or a Model.create call, not a simple assignment

    MethodMapper.assignments_for(@klazz).should_not include( MethodMapper.belongs_to_for(@klazz) )
    MethodMapper.assignments_for(@klazz).should_not include( MethodMapper.has_many_for(@klazz) )

  end

  it "should find method details correctly for different forms of a column name" do


    ["Count On hand", 'count_on_hand', "Count OnHand", "COUNT ONHand"].each do |format|

      method_details = MethodMapper.find_method_detail( @klazz, format )

      method_details.class.should == MethodDetail

      puts method_details.inspect

      method_details.operator.should == 'count_on_hand'
      method_details.assignment.should == 'count_on_hand'
      method_details.operator_for(:assignment).should == 'count_on_hand'

      method_details.operator_for(:belongs_to).should be_nil
      method_details.operator_for(:has_many).should be_nil

      method_details.belongs_to.should be_nil
      method_details.has_many.should be_nil


      method_details.col_type.should_not be_nil
      method_details.col_type.name.should == 'count_on_hand'
      method_details.col_type.default.should == 0
      method_details.col_type.sql_type.should include 'int'   # works on mysql and sqlite
      method_details.col_type.type.should == :integer
    end
  end

  it "should populate method details correctly for has_many forms of association name" do


    MethodMapper.has_many[@klazz].should include('product_option_types')


    ["product_option_types", "product option types", 'product Option_types', "ProductOptionTypes", "Product_Option_Types"].each do |format|
      method_details = MethodMapper.find_method_detail( @klazz, format )

      method_details.name.should eq( format )

      method_details.operator_for(:has_many).should eq('product_option_types')
      method_details.operator_for(:belongs_to).should be_nil
      method_details.operator_for(:assignment).should be_nil

      method_details.operator().should eq('product_option_types')

      method_details.has_many.should   == 'product_option_types'
      method_details.assignment.should be_nil
      method_details.col_type.should be_nil
      
    end
  end


  it "should not populate anything when  non existent column name" do
    ["On sale", 'on_sale'].each do |format|
      mmap = MethodMapper.find_method_detail( @klazz, format )

      mmap.class.should == MethodDetail
      mmap.assignment.should be_nil
      mmap.has_many.should be_nil
      mmap.col_type.should be_nil
    end
  end

  it "should enable correct assignment and sending of a value on Product" do

    method = MethodMapper.find_method_detail( @klazz, 'count on hand' )
    method.operator.should == 'count_on_hand'

    klazz_object = @klazz.new

    klazz_object.should be_new_record

    method.assign( klazz_object, 2 )

    klazz_object.count_on_hand.should == 2

    method = MethodMapper.find_method_detail( @klazz, 'SKU' )
    method.operator.should == 'sku'
    
    method.assign( klazz_object, 'TEST_SK 001')
    
    klazz_object.sku.should == 'TEST_SK 001'

  end

  it "should enable assignment to association of new AR model" do

    MethodMapper.find_operators( @klazz )

    mmap = MethodMapper.find_method_detail( @klazz, 'taxons' )

    mmap.has_many.should == 'taxons'
    mmap.operator.should == 'taxons'

    klazz_object = @klazz.new

    # NEW ASSOCIATION ASSIGNMENT  v.,mn
    klazz_object.send( mmap.has_many ) << Taxon.new

    klazz_object.taxons.size.should == 1

    klazz_object.send( mmap.has_many ) << [Taxon.new, Taxon.new]
    klazz_object.taxons.size.should == 3

  end

  it "should enable assignment to association of existing AR model" do

    mmap = MethodMapper.find_method_detail( @klazz, 'taxons' )
    mmap.operator.should == 'taxons'

    #txn = Taxon.find_or_create_by_name( 'RSpecTestTaxon' )

    #t = Taxonomy.find_or_create_by_name( 'BlahSpecTest', :root => txn )

    if @product
      sz = @product.taxons.size
      @product.send(mmap.has_many) << t.root
      @product.taxons.size.should == sz + 1
    else
      puts "WARNING : Test not run could not find any Test Products"
    end

  end


end