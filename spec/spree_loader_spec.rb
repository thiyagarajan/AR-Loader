require File.dirname(__FILE__) + '/spec_helper'

require 'spree_helper'

include ARLoader
  
describe 'SpreeLoader' do

  before(:all) do
    db_connect( 'test_file' )    # , test_memory, test_mysql
    Spree.load
    Spree.migrate_up

    @klazz = Product

    # TODO create proper suite of fixtures for Spree testing
    @prop1 = Property.find_or_create_by_name( 'RSpecTestProperty')
    @prop2 = Property.find_or_create_by_name( 'AN Other RSpecTestProperty')
    @prop3 = Property.find_or_create_by_name( 'AN Other RSpecTestProperty')

  end

  before do

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

    MethodMapper.column_types[@klazz].size.should == @klazz.columns.size
  end


  it "should find method details correctly for different forms of a column name" do

    ["Count On hand", 'count_on_hand', "Count OnHand", "COUNT ONHand"].each do |format|

      method_details = MethodMapper.find_method_detail( @klazz, format )

      method_details.operator.should == 'count_on_hand'
      method_details.operator_for(:assignment).should == 'count_on_hand'

      method_details.operator_for(:belongs_to).should be_nil
      method_details.operator_for(:has_many).should be_nil

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
      method_detail = MethodMapper.find_method_detail( @klazz, format )

      method_detail.should_not be_nil

      method_detail.operator_for(:has_many).should eq('product_option_types')
      method_detail.operator_for(:belongs_to).should be_nil
      method_detail.operator_for(:assignment).should be_nil
    end
  end


  it "should enable correct assignment to a column on Product" do

    method_detail = MethodMapper.find_method_detail( @klazz, 'count on hand' )
    method_detail.operator.should == 'count_on_hand'

    klazz_object = @klazz.new

    klazz_object.should be_new_record

    method_detail.assign( klazz_object, 2 )
    klazz_object.count_on_hand.should == 2

    method_detail.assign( klazz_object, 5 )
    klazz_object.count_on_hand.should == 5

    method = MethodMapper.find_method_detail( @klazz, 'SKU' )
    method.operator.should == 'sku'
    
    method.assign( klazz_object, 'TEST_SK 001')
    klazz_object.sku.should == 'TEST_SK 001'

  end

  it "should enable assignment to has_many association on new object" do
 
    method_detail = MethodMapper.find_method_detail( @klazz, 'taxons' )

    method_detail.operator.should == 'taxons'

    klazz_object = @klazz.new

    klazz_object.taxons.size.should == 0

    # NEW ASSOCIATION ASSIGNMENT

    # assign via the send operator directly on load object
    klazz_object.send( method_detail.operator ) << Taxon.new

    klazz_object.taxons.size.should == 1

    klazz_object.send( method_detail.operator ) << [Taxon.new, Taxon.new]
    klazz_object.taxons.size.should == 3

    # Use generic assignment on method detail - expect has_many to use << not =
    method_detail.assign( klazz_object, Taxon.new )
    klazz_object.taxons.size.should == 4

    method_detail.assign( klazz_object, [Taxon.new, Taxon.new])
    klazz_object.taxons.size.should == 6
  end

  it "should enable assignment to has_many association using existing objects" do

    MethodMapper.find_operators( @klazz )

    method_detail = MethodMapper.find_method_detail( @klazz, 'product_properties' )

    method_detail.operator.should == 'product_properties'

    klazz_object = @klazz.new

    ProductProperty.new(:property => @prop1)

    # NEW ASSOCIATION ASSIGNMENT
    klazz_object.send( method_detail.operator ) << ProductProperty.new

    klazz_object.product_properties.size.should == 1

    klazz_object.send( method_detail.operator ) << [ProductProperty.new, ProductProperty.new]
    klazz_object.product_properties.size.should == 3

    # Use generic assignment on method detail - expect has_many to use << not =
    method_detail.assign( klazz_object, ProductProperty.new(:property => @prop1) )
    klazz_object.product_properties.size.should == 4

    method_detail.assign( klazz_object, [ProductProperty.new(:property => @prop2), ProductProperty.new(:property => @prop3)])
    klazz_object.product_properties.size.should == 6

  end

  it "should process a simple .xls spreadsheet" do

    Zone.delete_all

    loader = ExcelLoader.new(Zone)

    count = Zone.count
    loader.load( $fixture_path + '/SpreeZoneExample.xls')

    loader.loaded_count.should == (Zone.count - count)
  end

  it "should process a simple csv file", :focus => false do

    Zone.delete_all

    loader = CsvLoader.new(Zone)

    count = Zone.count
    loader.load( $fixture_path + '/SpreeZoneExample.csv')

    loader.loaded_count.should == (Zone.count - count)
  end

  it "should load Products via specific Spree loader", :focus => true do

    require 'product_loader'

    Product.delete_all; Variant.delete_all; Taxon.delete_all
    
    count = Product.count

    loader = ARLoader::ProductLoader.new

    # REQUIRED 'set' methods on Product i.e will not validate/save without these

    loader.load($fixture_path + '/SpreeProducts.xls', :mandatory => ['sku', 'name', 'price'] )

    loader.loaded_count.should == (Product.count - count)
  end

end