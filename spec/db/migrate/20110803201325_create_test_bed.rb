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

    # belongs_to  :project
    create_table :milestones do |t|
      t.string     :name
      t.datetime   :datetime, :default => nil
      t.decimal    :cost, :precision => 8, :scale => 2, :default => 0.0
      t.references :project
      t.timestamps
    end

    create_table :categories do |t|
      t.string   :name
      t.timestamps
    end

     # testing has_belongs_to_many
    create_table :categories_projects, :id => false do |t|
      t.references :category
      t.references :project
    end

    create_table :versions do |t|
      t.string   :name
      t.timestamps
    end

    # testing project has_many release + versions :through
    create_table :releases do |t|
      t.string   :name
      t.references :project
      t.references :version
      t.timestamps
    end

  end

  def self.down
    drop_table :projects
    drop_table :categories
    drop_table :releases
    drop_table :versions
    drop_table :categories_projectss
    drop_table :milestones
  end
end
