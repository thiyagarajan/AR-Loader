## AR Loader

General active record loader for populating database with seed data from various sources,
including csv files and .xls files (Excel Spreadsheets)

Simplifies the specification and loading of data from such files into any active record supported database.

Aims to generically and seamlessly, handle loading an active record model's attributes and it's associations,
based on reflection against the supplied model.

So rather than hard coded mappings, uses the file's column headings to map data to model's attributes and associations,
which makes it extendable via file data rather than requiring new coding.

Simply add new column to Excel/Open Office spreadsheet, or csv file with new
attribute or association name, and loader will attempt to find correct association and populate AR object with row data.

The Loader attempts to handle various human read-able forms of column names.

For example, given an association on the model called, product_properties, will successfully load
from columns with headings such as 'product_properties', 'Product Properties', 'ProductProperties' 'product properties' etc

For has_many associations, either multiple columns can be used or multiple values can be specified in a single column using suitable delimiters.

Complex associations/mappings, for example requiring complex lookups, can be handled by extending the loader engine.

Original focus was on support for the Open Source Spree e-commerce project, so includes specific loaders and rake tasks
for loading Spree Products, and associated data such as Product Variants, and Images.

## Installation

Add gem 'ar_loader' to your Gemfile/bundle, or install the latest gem as usual :

    `gem install ar_loader`

To use :

    require 'ar_loader'

To pull the tasks in, add call in your Rakefile :

    ArLoader::load_tasks

N.B - To use the Excel loader, Excel itself is NOT required, however
JRuby is required, since it uses Java's Apache POI under the hood to process file.

To use in a mixed Ruby setup, you can use a guard something like :

    if(RUBY_PLATFORM =~ /java/)
         gem 'activerecord-jdbcmysql-adapter'
    else
        gem 'mysql'
    end

## Example Spreadsheet

  An example Spreadsheet with headers and comments, suitable for giving to Clients
  to populate, can be found in test/examples/DemoSpreadsheet.xls

## Features

- *Direct Excel file support*

  Includes a wrapper around MS Excel File format, via Apache POI, which
  enables Products to be loaded directly from Excel files (Excel does not need to be installed) via JRuby.
  No need to save to CSV first.

  The java jars e.g - 'poi-3.6.jar' - are included.

- *Semi-Smart Name Lookup*

  Includes helper classes that find and store details of all possible associations on an AR class.
  Given a user supplied name, attempts to find the requested association.

  Example usage, load from a file or spreadsheet where the column names are only
  an approximation of the actual associations, so given 'Product Properties' heading,
  finds real association 'product_properties' to send or call on the AR object

- *Associations*

  Can handle 'many' type associations and enables multiple association objects to
  be added via single entry (column). See Details section.

- *Spree Rake Tasks*

  Rake tasks provided for Spree loading - currently supports Product with associations,
  and Image loading.

  **Product loading from Excel specifically requires JRuby**. 

  Example command lines:

    rake excel_load input=vendor\extensions\autotelik\fixtures\ExampleInfoWeb.xls

    rake excel_load input=C:\MyProducts.xls verbose=true'

- *Seamless Image loading can be achieved by ensuring SKU or class Name features in Image filename.

  Lookup is performed either via the SKU being prepended to the image name, or by the image name being equal to the **name attribute** of the klass in question.

  Images can be attached to any class defined with a suitable association. The class to use can be configured in rake task via
  parameter klass=Xyz.

  In the Spree tasks, this defaults to Product, so attempts to attach Image to a Product via Product SKU or Name.
 
  Image loading **does not** specifically require JRuby

  A report is generated in the current working directory detailing any Images in the paths that could not be matched with a Product.

  Example cmd lines :

      rake image_load input=vendor\extensions\autotelik\lib\fixtures
      rake image_load input="C:\images\Paintings' dummy=true
      rake image_load input="C:\images\TaxonIcons" skip_if_no_assoc=true klass=Taxon

## Example Wrapper Tasks for Spree Site Extension

These tasks show how to write your own high level wrapper task, that will seed the database from multiple spreedsheets.

The images in this example have been named with the SKU present in name (separated by whitespace) e.g "PRINT_001 Stonehenge.jpg"

A report is generated in the current working directory detailing any Images in the paths that could not be matched with a Product.

    require 'ar_loader'

    namespace :mysite do

    desc "Load Products for site"
    task :load, :needs => [:environment] do |t, args|

      [ "vendor/extensions/site/db/seed/Paintings.xls",
        "vendor/extensions/site/db/seed/Drawings.xls"
      ].each do |x|
        Rake::Task['autotelik:excel_load'].execute(
          :input => x,
          :verbose => true,
          :sku_prefix => ""
        )
      end
    end

    desc "Load Images for site based on SKU"
    task :load_images, :clean, :dummy, :needs => [:environment] do |t, args|

      if(args[:clean])
        Image.delete_all
        FileUtils.rm_rf( "public/assests/products" )
      end

      ["01_paintings_jpegs", "02_drawings_jpegs"].each do |x|

        # image names start with associated Product SKU,
        # skip rather then exit if no matching product found

        Rake::Task['autotelik:image_load'].execute(
          :input => "/my_site_load_info//#{x}",
          :dummy => args[:dummy],
          :verbose => false, :sku => true, :skip_if_no_assoc => true
        )  
      end
    end

## Details

### Associations

A single association column can contain multiple name/value sets in default form :

    Name1:value1, value2|Name2:value1, value2, value3|Name3:value1, value2 etc

So for example a Column for an 'Option Types' association on a Product,
 could contain 2 options with a number of values each :

'Option Types'
    size:small,medium,large|colour:red,white
    size:small|colour:blue,red,white

### Properties

The properties to associate with this product.
Properties are for small snippets of text, shared across many products,
and are for display purposes only.

An optional display value can be supplied to supplement the displayed text.

As for all associations can contain multiple name/value sets in default form :

    Property:display_value|Property:display_value

Example - No values :
    manufacturer|standard

Example - Display  values :
    manufacturer:somebody else plc|standard:ISOBlah21

## TODO

  - Make more generic, so have smart switching to Ruby and directly support csv,
    when JRuby and/or Excel not available.

  - Smart sorting of column processing order ....

    Does not currently ensure mandatory columns (for valid?) processed first.
    Since Product needs saving before associations can be processed, user currently
    needs to ensure SKU, name, price columns are among first columns

## License

Copyright:: (c) Autotelik Media Ltd 2011

Author ::   Tom Statter

Date ::     Feb 2011

The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.