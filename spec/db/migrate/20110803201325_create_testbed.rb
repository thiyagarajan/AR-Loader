class CreateTestBed < ActiveRecord::Migration
  
  def self.up

    create_table :test_model do |t|
      t.string   :value_as_string
      t.text     :value_as_text
      t.boolean  :value_as_boolean, :default => false
      t.datetime :value_as_datetime, :default => nil
      t.timestamps
    end

    create_table :test_association_model do |t|
      t.string     :value_as_string
      t.references :test_model
      t.timestamps
    end

  end

  def self.down
    drop_table :test_model
    drop_table :test_association_model
  end
end
