# AR Loader

## Intro

General Active Record Loader with current focus on support for Spree.

Fully extendable via spreadsheet headings.

Maps column headings to attributes and associations. Simply add new column to Excel with
attribute or association name, and loader will attempt to
find correct association and populate AR object with column data.

Can handle human read-able forms, so for example, given an association on AR model called,
product_properties, will map from column headings such as 'product_properties',
'Product Properties', 'product properties'  etc

## QUICK START

Include gem in your Rails project. Currently no support for AR usage outside a Rails Project.

## Example Spreadsheet

  An example Spreadsheet with headers and comments, suitable for giving to Clients
  to populate, can be found in test/examples/DemoSpreadsheet.xls

## Features

- Direct Excel support

  Includes a wrapper around MS Excel via Apache POI, which
  enables Products to be loaded directly from Excel via JRuby. No need to save to CSV first.

  The java jars e.g - 'poi-3.6.jar' - are included.

- Semi-Smart Name Lookup

  Includes helper classes that find and store details of all possible associations on an AR class
  and given a user supplied name attempt to find the requested association.

  Example usage, load from a file or spreadsheet where the column names are only
  an approximation of the actual associations, so given 'Product Properties' heading,
  finds real association 'product_properties' to send or call on the AR object

- Associations

  Enables multiple associations to be described in single entry (column)

- Spree Rake Tasks

  Rake tasks provided for Spree loading - currently supports Product with associations,
  and Image loading.

  **Product loading from Excel specifically requires JRuby**. Examples:

    jruby -S rake excel_load input=vendor\extensions\autotelik\fixtures\ExampleInfoWeb.xls
    jruby -S rake excel_load input=C:\MyProducts.xls verbose=true

  Images can be attached to any class, specified by parameter klass=XXX.
  Default is to attach to a Product.
  Image loading does not specifically require JRuby

  Fairly seamless Image loading can be achieved by ensuring the SKU or product Name
  feature in the image filename. Examples :

    rake image_load input=vendor\extensions\autotelik\lib\fixtures\
    rake image_load input="C:\images\Paintings' dummy=true
    rake image_load input="C:\images\TaxonIcons" skip_if_no_assoc=true klass=Taxon

## Example Wrapper Tasks for Site Extension

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

##= Properties

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

  -Make more generic, so have smart switching to Ruby and directly support csv,
  when JRuby and/or Excel not available.

  -Look to support Open Office.

  -Smart sorting of column processing order ....
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