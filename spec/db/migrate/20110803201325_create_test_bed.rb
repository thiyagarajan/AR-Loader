class CreateTestBed < ActiveRecord::Migration
  
  def self.up

    # has many :milestones
    create_table :projects do |t|
      t.string   :title
      t.string   :value_as_string
      t.text     :value_as_text
      t.boolean  :value_as_boolean, :default => false
      t.datetime :value_as_datetime, :default => nil
      t.integer  :value_as_integer, :default => 0
      t.decimal  :value_as_double, :precision => 8, :scale => 2, :default => 0.0
      t.timestamps
    end

    # belongs_to  :project, project => has_many
    create_table :milestones do |t|
      t.string     :name
      t.datetime   :datetime, :default => nil
      t.decimal    :cost, :precision => 8, :scale => 2, :default => 0.0
      t.references :project
      t.timestamps
    end

    # belongs_to  :project, project => has_one
    create_table :owners do |t|
      t.string   :name
      t.references :project
      t.timestamps
    end

    # has_belongs_to_many :project
    create_table :categories do |t|
      t.string   :reference
      t.timestamps
    end

    # testing has_belongs_to_many (hence no id)
    create_table :categories_projects, :id => false do |t|
      t.references :category
      t.references :project
    end

    create_table :versions do |t|
      t.string   :name
      t.timestamps
    end

    # testing project has_many release + versions :through
    create_table :loader_releases do |t|
      t.string   :name
      t.references :project
      t.references :version
      t.timestamps
    end


    create_table :long_and_complex_table_linked_to_versions do |t|
      t.references :version
    end

    create_table :empties do |t|
    end

  end

  def self.down
    drop_table :projects
    drop_table :categories
    drop_table :loader_releases
    drop_table :versions
    drop_table :categories_projectss
    drop_table :milestones
    drop_table :long_and_complex_table_linked_to_versions
    drop_table :empties
  end
end
